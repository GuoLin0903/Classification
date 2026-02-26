%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trans=np_som(poids,nb_voisins,moy,affin,logue);

% < function trans=np_som(poids,nb_voisins,moy,affin,logue) >
%
% --- *** --- *** ---
%
% Effectue le calcul des frontières par la méthode du NP_SOM sur une carte de Kohonen
%
% - La carte est représentée par les valeurs de "poids"
% - La matrice de sortie "trans" est de dimension m*m (où m est la taille du côté de la carte)
%   et représente pour chaque neurone le maximum de la distance de ses poids d'entrées
%   à ceux de ses voisins
% - Le paramètre nb_voisins définit combien de neurones adjacents (4 ou 8) sont pris en compte
% - Le paramètre moy, s'il est mis à 1, permet de calculer la moyenne des distances aux neurones
%   au lieu de leur maximum ; sinon sa valeur doit être 0
%
% Une figure est affichée représentant les frontières sur la carte en niveaux de gris
%
% --- *** --- *** ---

[n m]=size(poids);
m=floor(sqrt(m));
trans=zeros(m,m);
account=zeros(1,8);
for (i=1:m) 
   for (j=1:m)
      if (i<m) account(1,1)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i)*m+j))./abs(poids(:,(i-1)*m+j)+poids(:,(i)*m+j))); end
      if (i>1) account(1,2)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i-2)*m+j))./abs(poids(:,(i-1)*m+j)+poids(:,(i-2)*m+j))); end
		if (j<m) account(1,3)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i-1)*m+j+1))./abs(poids(:,(i-1)*m+j)+poids(:,(i-1)*m+j+1))); end
		if (j>1) account(1,4)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i-1)*m+j-1))./abs(poids(:,(i-1)*m+j)+poids(:,(i-1)*m+j-1))); end
		if ((i>1) & (j>1)) account(1,5)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i-2)*m+j-1))./abs(poids(:,(i-1)*m+j)+poids(:,(i-2)*m+j-1))); end
		if ((i>1) & (j<m)) account(1,6)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i-2)*m+j+1))./abs(poids(:,(i-1)*m+j)+poids(:,(i-2)*m+j+1))); end
		if ((i<m) & (j>1)) account(1,7)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i)*m+j-1))./abs(poids(:,(i-1)*m+j)+poids(:,(i)*m+j-1))); end
		if ((i<m) & (j<m)) account(1,8)=sum(abs(poids(:,(i-1)*m+j)-poids(:,(i)*m+j+1))./abs(poids(:,(i-1)*m+j)+poids(:,(i)*m+j+1))); end
      if (moy==1) trans(i,j)=sum(account(1,1:nb_voisins));
		      else trans(i,j)=max(account(1,1:nb_voisins)); end
      account=zeros(1,8);
   end
end

if (nargin<4) affin=0; end

%if (affin>0)
%   for (i=1:m) 
%      for (j=1:m)
%         
%      end
%   end
%end

if (nargin<5)
   logue=0;
end
if (logue~=0)
   trans=log(trans)/log(logue);
end

figure;
surf(trans); title('Visualisation des frontières'); xlabel('X'); ylabel('Y');
axis([1 m 1 m]);
colormap(1-gray);
%shading interp;
rotate3d on;