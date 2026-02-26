%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 function CDbw_fit = fitness_CDbw(x,nb_cga,limite,V,A)
 
%  load nb_cga
%  load limite
%  load correlations 
%  V=correlations;
%  load donnees_representatives_filtrees
%  A=donnees_representatives_filtrees;
 
 % Construction de la matrice des coordonnées des centres de classe 
 index=1;
for r=1:1:nb_cga
    for q=1:1:limite
        C(r,q)=x(index);
        index=index+1;
    end
end    

[n,p]=size(A);

idx=zeros(n,1);

D=distfun(A,C,V); % get distances between objects and seeds
[E,idx]=min(D,[],2);     % find smallest distances and seeds 

CoefCDbw=CDbw(A,idx,C,size(C,1));

CDbw_fit=-CoefCDbw;