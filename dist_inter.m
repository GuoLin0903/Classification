%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Dij,elim]=dist_inter(D,idx)

% function Dij=dist_inter(D,idx)
% 
% A partir de la matrice D des distances des points à tous les centres des
% clusters, et du vecteur idx définissant le n° du cluster auquel
% appartient un point, calcule la matrice Dij (kxk, sym) des distances
% inter-clusters ; la diagonale donne les distances intra-clusters (idem
% SumD)
%

nbf=size(D,2);              % nbf : nb de familles ou clusters
SD=zeros(nbf,nbf);     % matrice nulle de dim nbf*nbf 
N=zeros(nbf,1);         
for i=1:nbf
    Di=D(find(idx==i),:);     % Di : matrice des dist de chaque point du cluster i à tous les centres des classes
    SD(i,:)=sum(Di);        % SD : matrice des sommes, pr chq cluster, des dist points-centres
    N(i,1)=size(Di,1);       % N : nombre d'individus dans chaque cluster
end
Dij=zeros(nbf,nbf);

%%% indicateur de marquage de la présence d'une classe vide
elim=0;
for i=1:nbf
    if N(i,1)==0
    elim=elim+1;
    end
end
for i=1:nbf
    for j=i+1:nbf
       Dij(i,j)=SD(i,j)/N(i,1)+SD(j,i)/N(j,1);
   end
end
for i=1:nbf
    Dij(i,i)=SD(i,i)/N(i,1);
end

