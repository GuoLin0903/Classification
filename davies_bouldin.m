%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CoefDB=davies_bouldin(Dij,elim)

% function CoefDB=davies_bouldin(Dij)
%
% Dij: matrice k*k des distances inter et intra clusters.
%
% Cette fonction calcule le coef de Davies et Bouldin à partir de Dij, à
% savoir le rapport entre distances intraclusters et distances
% interclusters. 
%

R=[];
[n,nbf]=size(Dij);

for i=1:nbf
    for j=(i+1):nbf
        R(i,j)=(Dij(i,i)+Dij(j,j))/Dij(i,j);
    end
end
for i=1:nbf
    R(i,i)=0;
end
for i=2:nbf
    for j=1:(i-1)
        R(i,j)=R(j,i);
    end
end
RDB=zeros(nbf,1);
for i=1:nbf
    RDB(i)=max(R(i,:));
end
CoefDB=1/nbf*sum(RDB)+elim;
