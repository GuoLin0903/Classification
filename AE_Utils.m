classdef AE_Utils
    methods(Static)
        function cols = get_view_columns(E, modeVal)
            vars = E.Properties.VariableNames;
            base = {'eventID'};
            if ismember('hittime',vars),  base{end+1}='hittime'; end
            if ismember('x_mm',vars),     base{end+1}='x_mm'; end
            if ismember('t0_S1_us',vars), base{end+1}='t0_S1_us'; end
            if ismember('t0_S2_us',vars), base{end+1}='t0_S2_us'; end
            
            switch modeVal
                case 1 % Mini
                    cols = base;
                case 2 % Standard
                    s1_cols = vars(startsWith(vars, 'S1_'));
                    s2_cols = vars(startsWith(vars, 'S2_'));
                    cols = [base, s1_cols, s2_cols];
                    cols = unique(cols, 'stable');
                otherwise
                    cols = base;
            end
            cols = cols(ismember(cols, vars));
        end
        
        function C = table2cell_ui(T)
            vars = T.Properties.VariableNames; 
            n = height(T); m = numel(vars); 
            C = cell(n,m);
            for j=1:m
                col = T.(vars{j});
                if isstring(col) || iscategorical(col), C(:,j)=cellstr(col);
                elseif isnumeric(col) || islogical(col), C(:,j)=num2cell(col);
                elseif iscellstr(col), C(:,j)=col;
                elseif iscell(col), C(:,j)=cellfun(@(x) char(string(x)), col, 'UniformOutput', false);
                else, C(:,j)=arrayfun(@(x) char(string(x)), col, 'UniformOutput', false);
                end
            end
        end
    end
end