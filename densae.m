%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2012                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x,y,nbxy,indxy]=densae(datax,datay,type_rep,ener,nbx,nby,options,nb_elem)

% ----------------------------------------------------------------------
% densae(datax,datay,type_rep,ener,nbx,nby,options)
%
% Représentation de la densité de signaux dans un plan de représentation
% choisi
%
% datax : données suivant axe x
% datay : données suivant axe y
% type_rep : 1 temps-position
%            2 déformation-position
%            3 desci-descj
%            4 cpi-cpj
% ener : [] calcule le nb de signaux cumulés par maille
%        [vecteur énergie] calcul l'énergie cumulée par maille
% nbx : nombre d'éléments de maillage en x
% nby : nombre d'éléments de maillage en y 
% options : 0 pas de réduction de l'intervalle étudié
%           1 spécifications par l'utilisateur des limites en x et y
% ----------------------------------------------------------------------

if type_rep==4 && nargin==3
    ener=[];
    nbx=[];
    nby=[];
    options=0;
end

if nargin<8
    nb_elem=8;
end

%% Limites en x et y

limx=[];

if options==1
    % Réduction de l'intervalle en x
    limx=input('Limites suivant x [min max] : ');
    if isempty(limx)==0
        datay=datay(datax>=limx(1) & datax<=limx(2),1);
        datax=datax(datax>=limx(1) & datax<=limx(2),1);
        if isempty(ener)==0
            ener=ener(datax>=limx(1) & datax<=limx(2),1);
        end
    end
    
    % Réduction de l'intervalle en y
    limy=input('Limites suivant y [min max] : ');
    if isempty(limy)==0
        datax=datax(datay>=limy(1) & datay<=limy(2),1);
        datay=datay(datay>=limy(1) & datay<=limy(2),1);
        if isempty(ener)==0
            ener=ener(datay>=limy(1) & datay<=limy(2),1);
        end
    end
    
    % Application d'un ln
    if type_rep==3
    ln=input('Application d''un ln (0 ou 1 pour [descx descy]) : '); 
    if isempty(ln)==0
        if ln(1)==1
            datax=log(datax);
        end
        if ln(2)==1
            datay=log(datay);
        end
    end
    end
elseif type_rep==3
    ln=[];
end


%% Création du maillage

if type_rep==3 || type_rep==4
    medx=median(datax);
    dataxs=sort(datax);
    q1x=median(dataxs(dataxs<medx));
    q3x=median(dataxs(dataxs>medx));
    largx=(q3x-q1x)/nb_elem; 
    nbx=ceil(abs(max(datax)-min(datax))/largx);
    
    medy=median(datay);
    datays=sort(datay);
    q1y=median(datays(datays<medy));
    q3y=median(datays(datays>medy));
    largy=(q3y-q1y)/nb_elem;
    nby=ceil(abs(max(datay)-min(datay))/largy);    
end

% Définition des intervalles
intx(:,1)=linspace(floor(10*min(datax))/10,ceil(10*max(datax))/10,nbx);
intx(1:size(intx,1)-1,2)=intx(2:size(intx,1),1);
intx=intx(1:size(intx,1)-1,:);

if type_rep==1 || type_rep==2 %arrondi à l'entier si position en y
    inty(:,1)=linspace(floor(min(datay)),ceil(max(datay)),nby);
else 
    inty(:,1)=linspace(floor(10*min(datay))/10,ceil(10*max(datay))/10,nby);
end
inty(1:size(inty,1)-1,2)=inty(2:size(inty,1),1);
inty=inty(1:size(inty,1)-1,:);

% Définition des coordonnées auxquelles seront reportées les valeurs de
% densité
x=intx(:,1)+(0.5*(intx(2,1)-intx(1,1)));
y=inty(:,1)+(0.5*(inty(2,1)-inty(1,1)));

% Ajout de 1 à la dernière borne du dernier intervalle pour être sûr 
% d'inclure tous les signaux dans le comptage
intx(size(intx,1),2)=intx(size(intx,1),2)+1; 
inty(size(inty,1),2)=inty(size(inty,1),2)+1; 


%% Calcul des densités

nbxy=zeros(size(y,1),size(x,1));
indxy=cell(size(y,1),size(x,1));

% Calcul du nombre de signaux par maille
if isempty(ener)==1
    for i=1:size(intx,1)
        for j=1:size(inty,1)
            nbxy(j,i)=size(find(datax>=intx(i,1) & datax<intx(i,2) & datay>=inty(j,1) & datay<inty(j,2)),1); 
            indxy{j,i}(:,1)=find(datax>=intx(i,1) & datax<intx(i,2) & datay>=inty(j,1) & datay<inty(j,2)); 
        end
    end
% OU Calcul de l'énergie cumulée par maille    
else
    disp('Quel type de données d''énergie sont à traiter ?')
    type_e=input('[1] Energie, attoJ - [2] Criticité : ');
    if type_e==1
        for i=1:size(intx,1)
            for j=1:size(inty,1)
                nbxy(j,i)=sum(ener(datax>=intx(i,1) & datax<intx(i,2) & datay>=inty(j,1) & datay<inty(j,2)),1);   
            end
        end
    else
        for i=1:size(intx,1)
            for j=1:size(inty,1)
                nbxy(j,i)=median(ener(datax>=intx(i,1) & datax<intx(i,2) & datay>=inty(j,1) & datay<inty(j,2)),1);
            end
        end
    end
end


%% Préparation de la matrice pour représentation

if isempty(ener)==0 && type_e==1 % Pour affichage de l'énergie en échelle log
    app_log=input('Application d''un log [o/n] : ','s');
    if app_log=='o'
        nbxy_gr=log10(nbxy);
        % Remplacement des -Inf par 0
        [a(:,1),a(:,2)]=find(nbxy_gr==-Inf);
        for i=1:size(a,1)
            nbxy_gr(a(i,1),a(i,2))=0;
        end
    else nbxy_gr=nbxy;
    end
else nbxy_gr=nbxy;
end

% Ajout de lignes et colonnes en début et fin de matrice pour
% représentation sur l'ensemble de l'intervalle considéré
if type_rep==1 || type_rep==2  
    x_gr=[floor(10*min(datax))/10;x;ceil(10*max(datax))/10];
    y_gr=[floor(min(datay));y;ceil(max(datay))];

    nbxy_gr=[nbxy_gr(1,:);nbxy_gr;nbxy_gr(size(nbxy_gr,1),:)];
    nbxy_gr=[nbxy_gr(:,1) nbxy_gr nbxy_gr(:,size(nbxy_gr,2))];

    % Ajout d'une colonne de 0 pour temps ou déformation en abscisse
    if isempty(limx)==1 || (isempty(limx)==0 && limx(1)==0)
        nbxy_gr=[zeros(size(y_gr,1),1) nbxy_gr];
        x_gr=[0; x_gr];
    end
    
    % Calcul des cumuls par intervalle de position (seulement pour types 1 et
    % 2)
%     nbxy_grc=100*cumsum(nbxy,2)./sum(sum(nbxy));
    nbxy_grc=cumsum(nbxy,2);
    nbxy_grc=[nbxy_grc(1,:);nbxy_grc;nbxy_grc(size(nbxy_grc,1),:)];
    nbxy_grc=[nbxy_grc(:,1) nbxy_grc nbxy_grc(:,size(nbxy_grc,2))];
    
    % Ajout d'une colonne de 0 pour temps ou déformation en abscisse
    if isempty(limx)==1 || (isempty(limx)==0 && limx(1)==0)
        nbxy_grc=[zeros(size(y_gr,1),1) nbxy_grc];
    end

else
    x_gr=x;
    y_gr=y;
end


%% Tracé

% Définition des labels

switch type_rep
    case 1
        label_x='Temps, s';
        label_y='Position, mm';
    case 2
        label_x='Déformation, %';
        label_y='Position, mm';
    case 3
        desc=input('Descripteurs en x et y [x y] : ');
        if isempty(ln)==0 && ln(1)==1
            label_x=['ln( ' intitule(desc(1)) ' )'];
        else
            label_x=intitule(desc(1));
        end
        if isempty(ln)==0 && ln(2)==1
            label_y=['ln( ' intitule(desc(2)) ' )'];
        else
            label_y=intitule(desc(2));
        end
    case 4
        if nargin==7
            desc=input('CP en x et y [x y] : ');
            if isempty(desc)==1
                desc=[1 2];
            end
            label_x=['CP' num2str(desc(1))];
            label_y=['CP' num2str(desc(2))];   
        end
end        

if isempty(ener)==1
    label_z='Nombre de sources par maille';
    label_z2='Nombre cumulé de sources';
    label_cb='Nombre de sources par maille';
    label_cb2='Nombre cumulé de sources';
else
    if type_e==1
        label_z='Energie par maille';
        label_z2='Energie par maille cumulée';
        label_cb2='Energie, attoJ';
        if app_log=='o'
            label_cb='log(Energie par maille, attoJ)';
        else
            label_cb='Energie par maille, attoJ';
        end
    else
        label_z='Criticité médiane par maille';
        label_cb='Criticité médiane par maille';
    end
end

% Tracé 3D
if type_rep~=4    
    figure
    surfc(x_gr,y_gr,nbxy_gr)

    xlabel(label_x)
    ylabel(label_y)
    zlabel(label_z)

    view(0,90)
    shading interp
end

% Tracé contour - Vue de dessus
if nargin>3
    figure
    contourf(x_gr,y_gr,nbxy_gr)

    xlabel(label_x)
    ylabel(label_y)
    title(label_z)
    cl1=colorbar;
    ylabel(cl1,label_cb)
end

% Tracés en cumulé
if type_rep==1 || type_rep==2 
    
    if isempty(ener)==1 || (isempty(ener)==0 && type_e==1)

    % Tracé 3D
    figure
    surfc(x_gr,y_gr,nbxy_grc)

    xlabel(label_x)
    ylabel(label_y)
    zlabel(label_z2)

    view(0,90)
    shading interp
    
    % Tracé contour - Vue de dessus
    figure
    contourf(x_gr,y_gr,nbxy_grc)

    xlabel(label_x)
    ylabel(label_y)
    title(label_z2)
    cl2=colorbar;
    ylabel(cl2,label_cb2)
    
    end
end