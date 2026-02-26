%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a_sil,b_sil]=dist_sil(donnees,idx,V,matdist)

% function [a,b]=dist_sil(idx,donnees)
% calcul des scalaires a et b permettant de calculer la silhouette de
% chaque signal
% nouvelle version : la distance de chaque point à tous les autres est
% calculée en amont (gain important en temps de calcul)

nbf=max(idx);
nbsig=size(donnees,1);

a_sil=zeros(size(donnees,1),1);
b_sil=zeros(size(donnees,1),1);

% Calcul de la matrice des distances entre points, si non renseignée
if nargin<4
    
    matdist=cell(ceil(nbsig/100),100);
    for i=1:nbsig
        li=ceil(i/100);
        co=i-100*(li-1);
        matdist{li,co}=distfun(donnees,donnees(i,:),V);
    end

end

ind=cumsum(ones(size(donnees,1),1));

for i=1:nbsig
       
    % Calcul des indices de ligne et colonne pour recherche dans matdist
    li=ceil(i/100);
    co=i-100*(li-1);
        
    B_sil=zeros(1,nbf);

    for j=1:nbf        
        
        if j==idx(i,1)
           a_sil(i,1)=mean(matdist{li,co}(idx==j & ind~=i,1));
           B_sil(1,j)=inf;  
        else B_sil(1,j)=mean(matdist{li,co}(idx==j & ind~=i,1));
        end
    
    end
    
    b_sil(i,1)=min(B_sil(1,:)); 
    
    clear B_sil
    
end
