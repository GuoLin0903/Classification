%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_loc,log_essai,indWF]=localize(data,V,d,num_capteur,nb_param,option,coef)

% < function data_loc=localize(data,V,d,num_capteur,nb_param,option,coef) >
%
% A partir d'une matrice de données "brutes"  [Id, time, ch,... ] , ne 
% garde que événements localisés entre capteurs, et ne garde que les 
% paramètres de salves sur le capteur le plus proche. 
%
% - "V" et "d" sont la vitesse des ondes (en m/s) et la distance entre capteurs (en mm)
% 
% - num_capteur est l'indice du capteur gauche ou inférieur (côté x négatif)
%
% - la position x (distance de la salve au centre (mm)) remplace la colonne 
% <id> (colonne 1) dans la matrice data_loc.
%
% - option : permet de choisir de traiter les caractéristiques des salves 
% récupérées par un capteur en particulier. Renseigner directement le
% numéro du capteur choisi. Si égal à 0, les données traitées sont
% celles reçues sur le capteur le plus proche
%
% - la matrice coef a 3 colonnes : 1-temps 2-coef gamma 3-def. Elle est
% utilisée pour la localisation à vitesse variable
%
% Principe: calcule les delta-t entre 2 lignes consécutives ; si delta-t<delta-t-max,  
% il s'agit du meme événement détecté sur les 2 capteurs --> calcule la position x 
% entre les 2 capteurs, recopie la ligne i (plus proche capteur) avec la colonne "channel" 
% et en rajoutant la colonne "xposition" (1ere colonne).
%
% 

%% Saisie des paramètres (si localisation lancée dans Weasel)

if nargin==3
    log_essai=V;
    nb_param=d;
    clear V d
        
    disp(' ')
    d=input('Quelle est la distance entre les capteurs d''émission acoustique (en mm) [190 mm] ? ');
    if isempty(d), d=190; end
    log_essai=str2mat(log_essai,['Distance entre capteurs (mm) : ',num2str(d)]);
    
    disp(' ')
    V=input('Quelle est la vitesse de propagation initiale dans le matériau (en m/s) [9500 m/s] ? ');
    if isempty(V), V=9500; end
    log_essai=str2mat(log_essai,['Vitesse de propagation (m/s) : ',num2str(V)]);

    disp(' ')
    num_capteur=input('Quel est le numéro du capteur gauche ou inf [1] ?');
    if isempty(num_capteur), num_capteur=1; end
    log_essai=str2mat(log_essai,['Capteur gauche ou inf : ',num2str(num_capteur)]);

    disp(' ')
    option=input('Informations à traiter [0 : plus proche | X : num capteur] :');
    log_essai=str2mat(log_essai,['Infos traitées : ',num2str(option)]);

    disp(' ')
    chx_loc = input('La vitesse évolue-t-elle au cours de l''essai ? [o/n] ', 's');
    if isempty(chx_loc), chx_loc='n';end
    if chx_loc=='n'
        log_essai=str2mat(log_essai,'Vitesse constante');
        coef=[];
    elseif chx_loc=='o' || chx_loc=='y';
        [FileName,~] = uigetfile('*.txt','Sélectionnez le fichier coef');
        log_essai=str2mat(log_essai,'Vitesse variable');
        coef=importdata(FileName);
    end
end


%% Localisation

if nargin==6; coef=[]; end
if nargin>3; log_essai=[]; end

i=1;
dataL=data(:,1:nb_param+3);
idx=zeros(size(dataL,1),1);
loc=[];
[long larg]=size(data);

while i<long
    if dataL(i+1,nb_param+3)~=dataL(i,nb_param+3),
        % calcul de deltat entre 2 lignes successives
        deltat=dataL(i+1,2)-dataL(i,2);
        if isempty(coef)==0
            j=1;
            %si coef ne couvre pas tout l'intervalle de déformation de data
            %on considère que l'endommagement est constant au-delà de la
            %valeur max de temps de coef
            if dataL(i,2)>=coef(size(coef,1),1)
                vitesse=V*coef(size(coef,1),2);
            else
            while dataL(i,2) >= coef(j,1)
                j=j+1;
            end
            if j>1
            vitesse=V*(coef(j-1,2)+(coef(j,2)-coef(j-1,2))/(coef(j,1)-coef(j-1,1))*(dataL(i,2)-coef(j-1,1)));
            else vitesse=V;
            end
            end             
        else
            vitesse=V;
        end              
        deltat_max=d/(1000*vitesse);
        % deltat<deltat_max --> événement localisé, sinon éliminé
        if deltat<deltat_max
            idx(i)=1;
            if dataL(i,nb_param+3)==num_capteur  
                xposition=-500*vitesse*deltat;
                loc=[loc; xposition];
            else
                xposition=500*vitesse*deltat;
                loc=[loc; xposition];
            end
            i=i+2;
        else 
            i=i+1;
        end
    else 
        i=i+1;
    end
end

ind=find(idx==1);

if option~=0
    for i=1:size(ind,1)
        if data(ind(i),nb_param+3)~=option
            ind(i)=ind(i)+1;
        end
    end
end

data_loc=[loc data(ind,2:larg)];


%% Réduction de l'intervalle (si localisation lancée dans Weasel)

if nargin==3
    disp(' ')
    disp('Filtrage de la localisation aux extrémités')
    Border=input('A combien de mm souhaitez-vous réduire la zone à partir des capteurs [5] ?');
    if isempty(Border), Border=5; end
    data_loc=data_loc(data_loc(:,1)>=-d/2+Border & data_loc(:,1)<=d/2-Border,:);
    log_essai=str2mat(log_essai,['Zone éliminée (mm) : ',num2str(Border)]);
end

if nargout>2
    indWF=[ind data(ind,[nb_param+3 1])];
end