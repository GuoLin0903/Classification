%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [postACP,Val_propres,explic,Vec_propres,R]=ACP(Xs)

% function [R,Vec_propres,postACP,Val_propres,explic]=ACP(preACP)
% 
% Standardise la matrice de données "preACP", puis calcule sa matrice de
% corrélation R, les composantes principales de R, les valeurs propres et le
% pourcentage d'explication de la variance par les premières composantes
% principales.
% 
% R : matrice de corrélation
% Vec_propres : vecteurs propres (composantes principales)
% postACP : données standardisées exprimées dans la base des vecteurs propres
% Val_propres : valeurs propres
% explic(i) : pourcentage d'explication de la variance totale par les i
%             premiers vecteurs propres
%

R=corrcoef(Xs);         % R : matrice de corrélation %R=1/(n-1)*Xs'*Xs;  

[Vec_propres,D]=eig(R); % Vec_propres : vecteurs propres, D : matrice diag des valeurs propres
postACP=Xs*Vec_propres; % postACP : données exprimées dans la base des vecteurs propres
%S=U*sqrt(D);           % S : matrice de structure (ou des saturations)
Val_propres=diag(D)';

% Tri des CP par ordre décroissant des valeurs propres associées
[A,B]=sort(Val_propres,'descend');

Val_propres=A;
R=R(:,B);
Vec_propres=Vec_propres(:,B);
postACP=postACP(:,B);

% Calcul du pourcentage d'explication cumulé
explic=cumsum(Val_propres(1,:)/sum(Val_propres));

