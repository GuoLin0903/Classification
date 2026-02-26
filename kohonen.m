%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function poids=kohonen(inpt,m,nb_passages,radius_init,gain,dimingain,selection_descripteurs,germe,posx,posy);

% < function poids=kohonen(inpt,m,nb_passages,radius_init,gain,dimingain,germe,posx,posy) >
%
% --- *** --- *** ---
%
% Crée une carte de Kohonen et stocke les résultats dans la matrice "poids"
%
% - "inpt" représente les données d'apprentissage, elle doit _impérativement_ avoir été
%   formatée par l'une des fonctions : 'make_input' ou 'make_randinput'
% - "m" est la taille carrée de la carte (la carte est forcément de forme carrée,
%   et "m" est donc le nombre total de neurones, racine de "m" est la taille d'un côté)
% - "nb_passages" est le nombre de phases d'apprentissage successives sur l'ensemble des données
% - "radius_init" est le rayon d'apprentissage initial (en nb de neurones)
%   ( le rayon est diminué de manière progressive de façon à arriver à 1 en fin d'apprentissage )
% - "gain" est le gain initial, "dimingain" le facteur de diminution
%   ( à chaque itération, le gain courant est multiplié par "dimingain" )
%
% Un nombre de graphes égal au nombre de paramètres pour chaque signal est
% affiché, représentant pour chacun de ces paramètres la valeur des poids
% correspondant sur l'ensemble de la carte (l'ordre d'apparition des graphes
% est le même que celui des paramètres dans les données de "inpt")
%
% OPTIONNELS :
%
% - "germe" est un vecteur représentant les paramètres d'un germe à placer sur la carte
% - "posx" et "posy" sont les positions initiales de ce germe sur la carte
%
% --- *** --- *** ---

n=length(inpt(1,:));
dim=floor(sqrt(m));
poids=rand(n,m);%*0.5; 
if (nargin>7)
   [tempx,tempy]=size(germe);
	if (tempy>tempx) germe=germe'; end
   poids(:,(posx-1)*dim+posy)=germe;
end
%poids=ones(3,16)*0.5;
radius=radius_init;
dist=ones(1,m);
indices=ones(2,m);
com=1;
for i=1:dim
   for j=1:dim
      indices(1,com)=i;
      indices(2,com)=j;
      com=com+1;
   end
end

ll=length(inpt(:,1));
for compteur_principal=1:nb_passages
   %radius=1+floor(radius_init*(nb_passages-compteur_principal)/nb_passages);
   for i=1:ll
      %radius=1+floor(radius_init*(length(inpt(:,1))-i)/length(inpt(:,1)));
      radius=1+floor(radius_init*((nb_passages-compteur_principal+1)*ll-i)/(nb_passages*ll));
      tempinpt=inpt(i,:);
      for com=1:m
         dist(com)=sum((tempinpt'-poids(:,com)).^2);
      end   
      [onsenfout,mine]=min(dist);mine=mine(1);
      voisinagelin=abs(indices(1,:)-indices(1,mine));
      voisinagecol=abs(indices(2,:)-indices(2,mine));
      voisins=find(((voisinagelin<=radius)|(voisinagelin>=(dim-radius)))&((voisinagecol<=radius)|(voisinagecol>=(dim-radius))));
      for com=1:n
         poids(com,voisins)=poids(com,voisins)+gain*(tempinpt(com)-poids(com,voisins));
      end
      gain=gain*dimingain; 
   end
end


%Modification de la préparation des graphes (Arnaud)
%Initialisation des matrices
for i=1:size(inpt,2)
    eval(['graph',num2str(i),'=abs(ones(',num2str(dim),',',num2str(dim),'));']);
    %graf1=abs(ones(dim,dim));
end    



for k=1:size(inpt,2)
    for i=1:m   
    eval(['graph',num2str(k),'(indices(1,',num2str(i),'),indices(2,',num2str(i),'))=poids(',num2str(k),',',num2str(i),');']);
    %graf1(indices(1,i),indices(2,i))=poids(1,i);
    end
end   
   
  
%Tracé des graphes

[X,Y] = meshgrid(1:1:dim);

for k=1:size(inpt,2)
 figure;
 eval(['mesh(X,Y,graph',num2str(k),');']); xlabel('X'); ylabel('Y');
 [titr]=intitule(selection_descripteurs(k));
 eval(['title(''',titr,''');'])
 rotate3d on;  
    
end    