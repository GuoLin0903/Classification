%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Si,MatSi,KSi]=silhouette(donnees,idx,V,matdist)

if nargin<4
    [a_sil,b_sil]=dist_sil_old(donnees,idx,V);
else [a_sil,b_sil]=dist_sil(donnees,idx,V,matdist);
end

MatSi=zeros(size(donnees,1),1);

for i=1:size(donnees,1)
    MatSi(i,1)=(b_sil(i,1)-a_sil(i,1))/max(a_sil(i,1),b_sil(i,1));
end 

KSi=zeros(1,max(idx));

for j=1:max(idx)
    KSi(1,j)=mean(MatSi(idx==j,1));
end

Si=mean(MatSi,1);