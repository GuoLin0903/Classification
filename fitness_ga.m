%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 function CoefDB = fitness_ga(x,nb_cga,limite,V,A)
 
% Construction de la matrice des coordonnées des centres de classe 
index=1;
for r=1:1:nb_cga
    for q=1:1:limite
        C(r,q)=x(index);
        index=index+1;
    end
end    

D=distfun(A,C,V); % get distances between objects and seeds
[~,idx]=min(D,[],2); % find smallest distances and seeds 

% Nombre de signaux par classe
recap=zeros(1,nb_cga);
for s=1:nb_cga
    recap(s)=size(find(idx==s),1);
end

% Si une classe contient moins de 2% du jeu de données, DB=1
n=size(A,1);
if isempty(find(recap<0.02*n,1))==1
    [Dij,elim]=dist_inter(D,idx);
    CoefDB=davies_bouldin(Dij,elim);
else
    CoefDB=1;
end

 
 
