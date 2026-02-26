%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                     modifié par par Anne-Sophie Gillot(2015-2016)  %                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stat = graphe_cl(nb_classes,descx,descy)

%----------------------------------------------------------------------
% Représentation des classes
%
% Données d'entrée : 
%   - nb de classes
%   - 2 descripteurs choisis pour la représentation (x,y)
%   - le Workspace résultat de la classification est sélectionné
%   manuellement
%
% Pour le calcul des coordonnées des centres de classe :
%   - descripteurs utilisés pour la classification
%   - descripteurs sur lesquels un Ln a été appliqué
%----------------------------------------------------------------------

clc

%% Définition des marqueurs et couleurs utilisés

marq=['*';'o';'^'];
coul=['b';'r';'g';'m';'k'];

k=1; %indice pour changement de marqueur
l=1; %indice pour changement de couleur


%% Chargement des données

disp('-------------------------------------------------------------')
disp('Sélectionnez les fichiers PostACP et Solution à charger')
disp('-------------------------------------------------------------')

[FileName,PathName] = uigetfile('*.mat','Sélectionnez le fichier PostACP');
postACP = importdata([PathName FileName]);

data = postACP.data_loc_f; 
dataACP = postACP.data_classif;
ind_filt = postACP.ind_filt;
descript_ini = postACP.descript_ini;
matdesc = descript_ini(ind_filt,:);

[FileName2,PathName2] = uigetfile('*.mat','Sélectionnez le fichier Solution');
resultat = importdata([PathName2 FileName2]);

idx = resultat.idx;
MatSi = resultat.MatSi;
if isfield(resultat,'Centres')==0;
    CentresACP=resultat.C;
else
    CentresACP=resultat.Centres;
end

disp(' ')
type_fichier = input('Type de fichier de données à charger [a : AEwin ; b : autre] : ', 's');

switch type_fichier
    case 'a'
        TPP = data(:,[2 1 3 4]); % Temps, Position, Param1, Param2
    case 'b'
        disp(' ')
        chgt_param = input('Voulez-vous charger le fichier contenant temps, position et paramétriques ? [o/n] ', 's');
        if chgt_param == 'o'
            [FileName3,PathName3] = uigetfile('*.mat','Sélectionnez le fichier TPP');
            TPPnf = importdata([PathName3 FileName3]);
            TPP = TPPnf(ind_filt,:);
        end
end
            
disp(' ')
disp('Fichiers chargés')


%% Cas de lancement sans arguments d'entrée

if nargin==0
    descx=23;
    descy=24;
    
    nb_classes=str2num(FileName2(3));
end


%% Tracé

figure
for i = 1:nb_classes

    plot1 = plot(matdesc(idx==i,descx),matdesc(idx==i,descy),[marq(k) coul(l)],'MarkerSize',4);
    
    switch type_fichier
        case 'a'
            xlabel(intitule(descx));
            ylabel(intitule(descy));
        case 'b'
            xlabel(intitule_WFfeat(descx));
            ylabel(intitule_WFfeat(descy));
    end

    set(plot1,'DisplayName',['Classe ' num2str(i)]);
    hold on

    if k==length(marq)
        k=1;
    else
        k=k+1;
    end

    if l==length(coul)
        l=1;
    else
        l=l+1;
    end

end

%Préparation de la sauvegarde des fichiers

nom = input('Les courbes vont être sauvegardées dans le répertoire courant. Nom de l echantillon avec n° essai, boucle et nombre de classes: ','s'); %pour AS


%% Tracé des classes dans la base de l'ACP

disp(' ')
disp('-------------------------------------------------------------')
disp('Tracé des classes dans la base de l''ACP')
disp('-------------------------------------------------------------')
disp(' ')
qu_ACP=input('Voulez-vous tracer les classes dans la base de l''ACP ? [o/n] ','s');

if qu_ACP=='o'
    
%Indices de marqueur et couleur
k=1;
l=1;

%Tracé
figure
for i=1:nb_classes

    if size(dataACP,2)>2
        subplot(2,2,1)
    end
    plot1 = plot(dataACP(idx==i,1),dataACP(idx==i,2),[marq(k) coul(l)],'MarkerSize',4);
    xlabel('CP1');
    ylabel('CP2');
    set(plot1,'DisplayName',['Classe ' num2str(i)]);
    hold on

    plot12 = plot(CentresACP(i,1),CentresACP(i,2),'*','Color',[0.5 0.5 0.5],'MarkerSize',10,'LineWidth',2);
    set(plot12,'DisplayName',['Centre ' num2str(i)]);
    hold on

    if size(dataACP,2)>2
        subplot(2,2,2)
        plot2 = plot(dataACP(idx==i,1),dataACP(idx==i,3),[marq(k) coul(l)],'MarkerSize',4);
        xlabel('CP1');
        ylabel('CP3');
        set(plot2,'DisplayName',['Classe ' num2str(i)]);
        hold on
        
        plot22 = plot(CentresACP(i,1),CentresACP(i,3),'*','Color',[0.5 0.5 0.5],'MarkerSize',10,'LineWidth',2);
        set(plot22,'DisplayName',['Centre ' num2str(i)]);
        hold on

        subplot(2,2,3)
        plot3 = plot(dataACP(idx==i,2),dataACP(idx==i,3),[marq(k) coul(l)],'MarkerSize',4);
        xlabel('CP2');
        ylabel('CP3');
        set(plot3,'DisplayName',['Classe ' num2str(i)]);
        hold on
        
        plot32 = plot(CentresACP(i,2),CentresACP(i,3),'*','Color',[0.5 0.5 0.5],'MarkerSize',10,'LineWidth',2);
        set(plot32,'DisplayName',['Centre ' num2str(i)]);
        hold on
    end

    %Gestion des couleurs et marqueurs
    if k==length(marq)
    k=1;
    else
        k=k+1;
    end

    if l==length(coul)
        l=1;
    else
        l=l+1;
    end

end
titre= 'ACP_'; %pour AS
name = strcat(titre, nom);%pour AS
saveas(gcf, name, 'fig');%pour AS
saveas(gcf, name, 'jpg');
clear name;
end    

disp(' ')
disp('Voulez-vous tracer une représentation 3D des signaux dans la base')
qu_ACP3D = input('de l''ACP ? [o/n] ','s');

if qu_ACP3D == 'o'
    %Indices de marqueur et couleur
    l=1;
    
    %Tracé
    figure   
    for i = 1:nb_classes
        
        plot3D = scatter3(dataACP(idx==i,1),dataACP(idx==i,2),dataACP(idx==i,3),['o' coul(l)]);
        xlabel('CP1')
        ylabel('CP2')
        zlabel('CP3')
        set(plot3D,'DisplayName',['Classe ' num2str(i)]);
        hold on
        
%         if qu_c=='o' % A revoir car problème pour paramétrage de la couleur
%         plot3D2=scatter3(CentresACP(i,1),CentresACP(i,2),CentresACP(i,3),'*','Color',[0.5 0.5 0.5],'MarkerSize',10,'LineWidth',2);
%         set(plot3D2,'DisplayName',['Centre ' num2str(i)]);
%         hold on
%         end
        
        if l==length(coul)
        l=1;
        else
            l=l+1;
        end
    end
    

end


%% Tracé des cartographies avec centres de classe dans la base de l'ACP

disp(' ')
disp('-------------------------------------------------------------')
disp(' Tracé des cartographies avec centres de classe dans la base ')
disp('                         de l''ACP                           ')
disp('-------------------------------------------------------------')
disp(' ')
qu=input('Voulez-vous tracer les cartographies ? [o/n] ', 's');

if qu=='o'
    % Cartographie de CP2 vs CP1
    disp(' ')
    disp('Cartographie de CP2 vs CP1')
    densae(dataACP(:,1),dataACP(:,2),4,[],15,15,1);
    hold on
    plot(CentresACP(:,1),CentresACP(:,2),'ok')
    
    if size(dataACP,2)>=3
        disp(' ')
        disp('Cartographie de CP3 vs CP1')
        densae(dataACP(:,1),dataACP(:,3),4,[],15,15,1);
        hold on
        plot(CentresACP(:,1),CentresACP(:,3),'ok')
        
        disp(' ')
        disp('Cartographie de CP3 vs CP2')
        densae(dataACP(:,2),dataACP(:,3),4,[],15,15,1);
        hold on
        plot(CentresACP(:,2),CentresACP(:,3),'ok')
    end
end


%% Tracé des cumuls de signaux et énergie

disp(' ')
disp('-------------------------------------------------------------')
disp('Tracé des cumuls de signaux et énergie')
disp('-------------------------------------------------------------')
disp(' ')
qu = input('Voulez-vous les tracés des cumuls ? [o/n] ', 's');

if qu=='o'

disp(' ')
qu_x = input('Quelle grandeur utiliser en abscisse ? [t/p1/p2] ', 's');

switch qu_x
    case 't'
        axex = 1;
        label = 'Temps, s';
    case 'p1'
        axex = 3;
        label = 'Contrainte, MPa';
    case 'p2'
        axex = 4;
        label = 'Déformation, %';
end

if type_fichier == 'b'
    disp(' ')
    disp('Le fichier de données n''est pas de type AEwin.')
    col_en = input('Quel est l''indice de la colonne contenant les valeurs d''énergie ? ');
    en = matdesc(:,col_en);
else
    en = matdesc(:,9);
end

figure

l=1; %indice pour changement de couleur

for i=1:nb_classes

subplot(2,2,1)
plot3 = plot(TPP(idx==i,axex),cumsum(ones(size(TPP(idx==i,:),1),1)),['.-' coul(l)]);
set(plot3,'DisplayName',['Classe ' num2str(i)]);
xlabel(label)
ylabel('Nombre cumulé de sources')
title('Sources cumulées par classe')
hold on

subplot(2,2,2)
plot4 = plot(TPP(idx==i,axex),cumsum(en(idx==i)),['.-' coul(l)]);
set(plot4,'DisplayName',['Classe ' num2str(i)]);
xlabel(label)
ylabel('Energie cumulée, attoJ')
title('Energie cumulée par classe')
hold on

subplot(2,2,3)
plot32=plot(TPP(idx==i,axex),100*cumsum(ones(size(TPP(idx==i,:),1),1))/size(TPP(idx==i,:),1),['.-' coul(l)]);
set(plot32,'DisplayName',['Classe ' num2str(i)]);
xlabel(label)
ylabel('Nombre cumulé de sources, %')
title('Evolution normalisée des sources cumulées par classe')
hold on

subplot(2,2,4)
plot42=plot(TPP(idx==i,axex),100*cumsum(en(idx==i))/sum(en(idx==i)),['.-' coul(l)]);
set(plot42,'DisplayName',['Classe ' num2str(i)]);
xlabel(label)
ylabel('Energie cumulée, %')
title('Evolution normalisée de l''énergie cumulée par classe')
hold on

if l==length(coul)
    l=1;
else
    l=l+1;
end

end
titre= 'cumuls_'; %pour AS
name = strcat(titre, nom);%pour AS
saveas(gcf, name, 'fig');%pour AS
saveas(gcf, name, 'jpg');
clear name;
end


%% Tracé de la localisation des signaux par classe

disp(' ')
disp('-------------------------------------------------------------')
disp('Tracé de la localisation des signaux par classe')
disp('-------------------------------------------------------------')
disp(' ')
qu=input('Voulez-vous le tracé de la localisation ? [o/n] ', 's');

if qu=='o'
      
disp(' ')
qu_x = input('Quelle grandeur utiliser en abscisse ? [t/p1/p2] ', 's');

switch qu_x
    case 't'
        axex = 1;
        label = 'Temps, s';
    case 'p1'
        axex = 3;
        label = 'Contrainte, MPa';
    case 'p2'
        axex = 4;
        label = 'Déformation, %';
end

figure

k=1; %indice pour changement de marqueur
l=1; %indice pour changement de couleur

for i=1:nb_classes

plot5 = plot(TPP(idx==i,axex),TPP(idx==i,2),[marq(k) coul(l)], 'MarkerSize', 4);
set(plot5,'DisplayName',['Classe ' num2str(i)]);
title('Localisation des sources par classe')
xlabel(label)
ylabel('Position, mm')
hold on

if k==length(marq)
    k=1;
else
    k=k+1;
end

if l==length(coul)
    l=1;
else
    l=l+1;
end

end
titre= 'localisation_'; %pour AS
name = strcat(titre, nom);%pour AS
saveas(gcf, name, 'fig');%pour AS
saveas(gcf, name, 'jpg');
clear name;
end


%% Tracé des boîtes à moustache des descripteurs

disp(' ')
disp('-------------------------------------------------------------')
disp('Analyse de la distribution des descripteurs')
disp('-------------------------------------------------------------')
disp(' ')
disp('Voulez-vous tracer les boîtes à moustache de certains')
qu=input('descripteurs par classe ? [o/n] ','s');

if qu=='o'
    
    disp('Saisissez entre crochets les descripteurs à étudier (Ex: [1 4 9])')
    desc=input('([] pour représenter tous les descripteurs) ');
    
    position=[];
    
    if isempty(desc)==1
        desc=[1:size(classe,2)-5];
    end
    
    %Création des labels
    for i=1:nb_classes
        labels{1,i}=['Classe ',num2str(i)];
        position=[position,i];
    end
    
    %Tracé des boîtes à moustache et calcul de (Q1, med, Q3)
    for j=1:size(desc,2)
        k=desc(1,j);
        figure

        box=boxplot(matdesc(:,k),idx,'labels',labels,'positions',position);    
        set(box(7,:),'Visible','off');
        set(gca,'ytickmode','auto','yticklabelmode','auto','ylimmode','auto') 

        switch type_fichier
            case 'a'
                ylabel(intitule(k));
                title(intitule(k));
            case 'b'
                ylabel(intitule_WFfeat(k));
                title(intitule_WFfeat(k));
        end
        
        name = strcat(num2str(k),'_', nom);%pour AS
        saveas(gcf, name, 'fig');%pour AS
        saveas(gcf, name, 'jpg');
        clear name; 
    end
       
end


%% Calcul des statistiques de chaque descripteur et tracé de l'enveloppe médiane des classes

if type_fichier == 'a'

stat=zeros(5,nb_classes*18);

for i=1:nb_classes
    
    for j=1:18
        
    col=i+(nb_classes*(j-1));
    
    temp = matdesc(idx==i,j);
    tempsort = sort(temp);

    med=median(temp);
    Q1=median(tempsort(find(tempsort<med)));
    Q3=median(tempsort(find(tempsort>med))); 

    stat(1,col)=j;
    stat(2,col)=i;
    stat(3,col)=Q1;
    stat(4,col)=med;
    stat(5,col)=Q3;

    clear temp Q1 med Q3
        
    end
    
end

figure

l=1; %indice pour changement de couleur

for i=1:nb_classes

    % Enveloppe médiane
    
    amp(i)=stat(4,find(stat(1,:)==4 & stat(2,:)==i));
    dur(i)=stat(4,find(stat(1,:)==3 & stat(2,:)==i));
    rise(i)=stat(4,find(stat(1,:)==1 & stat(2,:)==i));
    count(i)=ceil(stat(4,find(stat(1,:)==2 & stat(2,:)==i))/10);

    % Coordonnées des points particuliers

        %Origine
        xO(i)=0;
        yO(i)=0;

        %Maxi
        xA(i)=rise(i);
        yA(i)=amp(i);

        %Fin
        xB(i)=dur(i);
        yB(i)=0;

        %Equation des 2 droites enveloppe
        a1(i)=amp(i)/rise(i);

        a2(i)=-amp(i)/(dur(i)-rise(i));
        b2(i)=dur(i)*amp(i)/(dur(i)-rise(i));

end

xmax=ceil(max(xB(:))/100)*100;
ymax=ceil(max(yA(:))/10)*10;

disp(' ')
disp('-------------------------------------------------------------')
disp('Tracé de l''enveloppe médiane de chaque classe')
disp('-------------------------------------------------------------')
disp(' ')

for i=1:nb_classes

    % Tracé

    subplot(ceil(nb_classes/2),2,i)
    plot6 = line([xO(i) xA(i) xB(i)],[yO(i) yA(i) yB(i)],'Color',coul(l),'LineWidth',1.5);
    xlim([0 xmax])
    ylim([0 ymax])
    xlabel('Temps, µs')
    ylabel('Amplitude, dB')
    
    title(['Enveloppe médiane - Classe ' num2str(i)])

    hold on

    for k=1:count(i)

        t=k*(dur(i)/(count(i)+1));

        if t<=rise(i)
            yt=a1(i)*t;
        else
            yt=a2(i)*t+b2(i);
        end

        line([t t],[0 yt],'Color',coul(l))
        hold on

    end

    if l==length(coul)
        l=1;
    else
        l=l+1;
    end

end
titre= 'enveloppe_'; %pour AS
name = strcat(titre, nom);%pour AS
saveas(gcf, name, 'fig');%pour AS
saveas(gcf, name, 'jpg');
clear name;
end


%% Tracé des silhouettes

tailleA=int8(ceil(sqrt(max(idx))));
tailleB=int8(ceil(max(idx)/tailleA));
figure;
for i=1:1:max(idx)

    Silh(:,1)=MatSi(idx==i,1);

    locate_subplot=['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(i) ')'];
    eval(locate_subplot);
    hist(Silh,100);
    moy=mean(Silh(:,1));
    xlabel(['Classe ',num2str(i)]); 
    ylabel('Nombre de signaux'); 
    xlim([-1 1]);
    title(['Silhouette moyenne : ' num2str(moy,4)])
titre= 'silhouette_'; %pour AS
name = strcat(titre, nom);%pour AS
saveas(gcf, name, 'fig');%pour AS
saveas(gcf, name, 'jpg');
clear name;
clear Silh;
end


%% Construction de la matrice finale
% 
% if nargout==4
% 
%     matrice_finale=zeros(size(data,1),23);
% 
%     matrice_finale(:,1:9)=data(:,size(data,2)-8:size(data,2));
% 
%     matrice_finale(:,10)=matrice_finale(:,1)./matrice_finale(:,3);
%     matrice_finale(:,11)=matrice_finale(:,3)./matrice_finale(:,4);
%     matrice_finale(:,12)=matrice_finale(:,3)-matrice_finale(:,1);
%     matrice_finale(:,13)=matrice_finale(:,4)./matrice_finale(:,1);
%     matrice_finale(:,14)=matrice_finale(:,4)./matrice_finale(:,12);
%     matrice_finale(:,15)=matrice_finale(:,1)./matrice_finale(:,12);
%     matrice_finale(:,16)=matrice_finale(:,9)./matrice_finale(:,4);
%     matrice_finale(:,17)=matrice_finale(:,6)./matrice_finale(:,2);
%     matrice_finale(:,18)=matrice_finale(:,4)./matrice_finale(:,5);
% 
%     matrice_finale(:,19)=data(:,1);
%     matrice_finale(:,20)=data(:,2);
%     matrice_finale(:,21)=idx;
% 
%     if size(data,2)==13
%         matrice_finale(:,22)=data(:,3);
%     end
%     if size(cl,2)==14
%        matrice_finale(:,22:23)=data(:,3:4);
%     end
% 
% else matrice_finale=[];
% 
% end
