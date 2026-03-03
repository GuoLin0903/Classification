classdef AE_Vis_TFD
    methods(Static)
        function draw(ax, x, fs, fmax_kHz, clim_db)
            if nargin < 5, clim_db = -60; end
            if nargin < 4, fmax_kHz = 500; end
            
            x = double(x(:));
            if all(x == 0), cla(ax); return; end
            x = x - mean(x); 
            
            try
                [TFR, t_idx, f_norm] = tfrsp(x);
            catch
                cla(ax); text(ax,0.5,0.5,'Error: tfrsp.m missing',...
                    'HorizontalAlignment','center','VerticalAlignment','middle'); return;
            end
            
            f_Hz  = f_norm(:) * fs; f_kHz = f_Hz / 1e3;
            pos = f_kHz >= 0; f_kHz = f_kHz(pos); TFR = TFR(pos,:);
            
            if ~isempty(fmax_kHz)
                idx = f_kHz <= fmax_kHz; 
                f_kHz = f_kHz(idx); TFR = TFR(idx,:); 
            end
            
            t_us = (t_idx(:).' - 1) / fs * 1e6;
            A = abs(TFR); A = A ./ (max(A(:)) + eps);
            A_db = 20*log10(A + eps); 
            A_db(A_db < clim_db) = clim_db;
            
            axes(ax); %#ok<LAXES>
            cla(ax); 
            imagesc(t_us, f_kHz, A_db); 
            set(ax,'YDir','normal'); 
            colormap(ax,'jet'); 
            caxis(ax,[clim_db 0]);
            xlabel(ax,'Time (\mus)'); 
            ylabel(ax,'Freq (kHz)'); 
            colorbar('peer',ax);
        end
    end
end