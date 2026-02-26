%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a_sil,b_sil]=dist_sil_old(donnees,idx,V)

% function [a,b]=dist_sil(idx,donnees)
% calcul des scalaires a et b permettant de calculer la silhouette de
% chaque signal

nbf=max(idx);

a_sil=zeros(size(donnees,1),1);
b_sil=zeros(size(donnees,1),1);

for i=1:1:size(donnees,1)
    
    if i==1
        Mat=donnees(2:size(donnees,1),:);
        id=idx(2:size(donnees,1),:);
        elseif i==size(donnees,1)
        Mat=donnees(1:size(donnees,1)-1,:);
        id=idx(1:size(donnees,1)-1,:);
        else
        Mat=[donnees(1:i-1,:);donnees(i+1:size(donnees,1),:)];    
        id=[idx(1:i-1,:);idx(i+1:size(donnees,1),:)];   
     end    
    
    B_sil=zeros(1,nbf);
    
    for j=1:nbf
        
        
        Aj=Mat(find(id==j),:);
       
        
        if j==idx(i,1)
           A_sil=distfun(Aj,donnees(i,:),V);
           a_sil(i,1)=mean(A_sil);
           B_sil(1,j)=inf;
           
           clear A_sil
           
        else
            
            B=distfun(Aj,donnees(i,:),V);
            B_sil(1,j)=mean(B);
        end
               
    clear Aj 
    
    end
    
    b_sil(i,1)=min(B_sil(1,:)); 
    
    clear B_sil Mat
    
end
