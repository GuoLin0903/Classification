%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Passage]=split(Tidx,nb_k)

for i=1:1:nb_k-2 % numéro de la colonne dans Idx (K=i1+1)
    ligne=1;
    for j=1:1:i+2 % n° de la classe dans K=1+2
        for k=1:1:i+1 % idem dans K=i+1
            count=0;
            for l=1:1:size(Tidx,1) % balayage des colonnes
                if Tidx(l,i+1)==j
                    if Tidx(l,i)==k
                        count=count+1;
                    end
                end   
            end
            Passage(ligne,i)=count;
            ligne=ligne+1;
        end
    end   
end
clear i j k l count
end
        