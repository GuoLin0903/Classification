classdef AE_Logic_Filter
    methods(Static)
        function mask = apply(E, F)
            % F is the filter struct from UI
            nEv = height(E);
            mask = true(nEv,1);
            
            % Spatial Filter
            if ismember('x_mm', E.Properties.VariableNames)
                if isfinite(F.xmin), mask = mask & (E.x_mm >= F.xmin); end
                if isfinite(F.xmax), mask = mask & (E.x_mm <= F.xmax); end
            end
            
            % Time Filter
            if ismember('hittime', E.Properties.VariableNames)
                if isfinite(F.tmin), mask = mask & (E.hittime >= F.tmin); end
            end
            
            % Feature Filters (S1/S2 independent check)
            m1 = true(nEv,1); m2 = true(nEv,1); hasFeat = false;
            
            % Check S1 features
            if ismember('S1_Amp_dB', E.Properties.VariableNames)
                hasFeat = true;
                if isfinite(F.rtmax), m1 = m1 & (E.S1_RiseTime_us <= F.rtmax); end
                if isfinite(F.amin),  m1 = m1 & (E.S1_Amp_dB >= F.amin); end
                if isfinite(F.amax),  m1 = m1 & (E.S1_Amp_dB <= F.amax); end
                if ismember('S1_FC_kHz',E.Properties.VariableNames)
                    if isfinite(F.fcmin), m1 = m1 & (E.S1_FC_kHz >= F.fcmin); end
                    if isfinite(F.fcmax), m1 = m1 & (E.S1_FC_kHz <= F.fcmax); end
                end
            end
            
            % Check S2 features
            if ismember('S2_Amp_dB', E.Properties.VariableNames)
                hasFeat = true;
                if isfinite(F.rtmax), m2 = m2 & (E.S2_RiseTime_us <= F.rtmax); end
                if isfinite(F.amin),  m2 = m2 & (E.S2_Amp_dB >= F.amin); end
                if isfinite(F.amax),  m2 = m2 & (E.S2_Amp_dB <= F.amax); end
                if ismember('S2_FC_kHz',E.Properties.VariableNames)
                    if isfinite(F.fcmin), m2 = m2 & (E.S2_FC_kHz >= F.fcmin); end
                    if isfinite(F.fcmax), m2 = m2 & (E.S2_FC_kHz <= F.fcmax); end
                end
            end
            
            if hasFeat
                % User logic: Use S1 OR Use S2?
                combined_m = false(nEv,1);
                if F.useS1, combined_m = combined_m | m1; end
                if F.useS2, combined_m = combined_m | m2; end
                % If neither checked, assuming pass nothing or pass all? 
                % Usually pass all if neither restricted, but UI implies restrictive.
                if ~F.useS1 && ~F.useS2, combined_m = true(nEv,1); end
                
                mask = mask & combined_m;
            end
        end
    end
end