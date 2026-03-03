classdef AE_Calc_Features
    methods(Static)
        function [Tfull, E_out] = run_and_merge(wave, fs, chS1, chS2, eventTime, k0_all, kE_all, E_in, hasAIC)
            fsInv = 1/fs; 
            numEvents = height(E_in);
            idx_use = (1:numEvents)';
            
            C = cell(numEvents, 1);
            
            % This loop can be changed to 'parfor' if parallel pool is available for speed
            for ii = 1:numEvents
                ev = idx_use(ii);
                k0 = max(1, k0_all(ev)); 
                kend = min(size(wave,1), kE_all(ev));
                
                seg = double(wave(k0:kend,:,ev));
                Nt = size(seg,1); 
                T2 = (0:Nt-1)'*fsInv;
                
                % S1
                V1 = seg(:,chS1);
                F1 = ExtractFeati_OPT(T2, V1, [], {fs, chS1, ev, eventTime(ev)});
                S1 = AE_Calc_Features.vec2struct(F1, 'S1_');
                
                % S2
                V2 = seg(:,chS2);
                F2 = ExtractFeati_OPT(T2, V2, [], {fs, chS2, ev, eventTime(ev)});
                S2 = AE_Calc_Features.vec2struct(F2, 'S2_');
                
                M = struct('eventID',ev, 'k0_samp',k0, 'kEnd_samp',kend, 'win_us',(kend-k0+1)/fs*1e6);
                C{ii} = AE_Calc_Features.merge_structs(M, S1, S2);
            end
            
            Tfull = struct2table(vertcat(C{:}));
            
            % Merge into E (keeping existing E columns safe)
            E_out = AE_Calc_Features.merge_into_E(E_in, Tfull);
        end
        
        function S = vec2struct(V, prefix)
            names={'hit','hittime','channel','Amp_dB','Dur_us','Energy_V2','ZCR_pct','RiseTime_us','TempCentroid_us','alpha', ...
                   'PP2_1','PP2_2','PP2_3','PP2_4','FC2_kHz','PF2_kHz','SSpread_kHz','SSkew','SKurt','SSlope','SRoff_kHz', ...
                   'SsqrtSpreadP_kHz','SSkewP','SKurtP','SRon_kHz','WPE1','WPE2','WPE3','WPE4','WPE5','WPE6','WPE7','WPE8','Entropy'};
            n=min(numel(V),numel(names)); S=struct();
            for i=1:n, S.([prefix names{i}])=V(i); end
        end
        
        function S = merge_structs(varargin)
            S=struct();
            for k=1:nargin
                f=varargin{k}; fn=fieldnames(f);
                for i=1:numel(fn), S.(fn{i})=f.(fn{i}); end
            end
        end
        
        function Eout = merge_into_E(Ein, Tfeat)
            Eout = Ein; 
            [lia,loc] = ismember(Tfeat.eventID, Eout.eventID);
            tv = Tfeat.Properties.VariableNames; 
            skip = {'eventID','k0_samp','kEnd_samp','win_us','hittime'};
            for i=1:numel(tv)
                v = tv{i}; if any(strcmp(v, skip)), continue; end
                dest = v;
                if endsWith(dest,'FC2_kHz'), dest = strrep(dest,'FC2','FC'); end
                if endsWith(dest,'PF2_kHz'), dest = strrep(dest,'PF2','PF'); end
                if ~ismember(dest, Eout.Properties.VariableNames), Eout.(dest) = nan(height(Eout),1); end
                tmp = Eout.(dest); tmp(loc(lia)) = Tfeat.(v)(lia); Eout.(dest) = tmp;
            end
        end
    end
end