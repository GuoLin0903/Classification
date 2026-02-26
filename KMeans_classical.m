%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         K-Means algorithm                          %
%                           (Version 1.1)                            %
%                                                                    %
%                                                                    %
%           Emmanuel MAILLET, Doctoral Student (2009/2012)           %
%                           (Version 1.1)                            %
%                [Algorithm optimisation, New criterion]             %
%                                                                    %
%             Arnaud SIBIL, Doctoral Student (2007/2010)             %
%                           (Version 1.0)                            %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear outil
disp('***************************************************************************')
disp('*           Classification des données d''émission acoustique              *')         
disp('*                    par la méthode des K-Moyennes                        *')
disp('***************************************************************************')
disp(' ')


%% Paramètres de l'algorithme

disp(' ')
fprintf(2,'***** Classification par les K-Moyennes ******')
disp(' ')
disp(' ') 
nb_c=input('Pour quel nombre de classes maximum souhaitez-vous réaliser une classification ? [10]');
if isempty(nb_c), nb_c=10; end
disp(' ')

iter=input('Combien d''itérations souhaitez-vous ? [15]');
if isempty(iter), iter=15; end
disp(' ')

input_log=['Nombre de classes max. : ',num2str(nb_c)];
log_essai=input_log;
input_log=['Nombre d''itérations : ',num2str(iter)];
log_essai=str2mat(log_essai,input_log);

critere=input('Critère à utiliser pour l''évaluation: [1]DB | [2] Si ?');
if isempty(critere), critere=1; end
disp(' ')
if critere==1
    input_log=['Critère de classification : Davies et Bouldin'];
    elseif critere==2
    input_log=['Critère de classification : Silhouettes'];
end    
log_essai=str2mat(log_essai,input_log);

nb_essais=input('Combien de fois souhaitez-vous réaliser la classification ? ');
disp(' ')

disp('Souhaitez-vous permettre l''initialisation des centres de classe');
init_auto=input('dans les zones de forte densité ? [o/n] ','s');
disp(' ')

if init_auto=='o'
    C_init=pts_denses(data_classif,val_propres);
    if size(C_init,1)<nb_c-1
        C_init(size(C_init,1):nb_c-1,size(C_init,2))=0;
    end
end

%% Préparation

basepath=pwd; %Dossier de base

optim_DB=zeros(nb_c-1,nb_essais);
optim_SI=zeros(nb_c-1,nb_essais);

tic % déclenchement du chronomètre

% Calcul de la matrice de distances entre points pour calcul des Si
disp('Calcul de la matrice de distances entre points...')
disp(' ')

nbsig=size(data_classif,1);
matdist=cell(ceil(nbsig/100),100);
for i=1:nbsig
    li=ceil(i/100);
    co=i-100*(li-1);
    matdist{li,co}=distfun(data_classif,data_classif(i,:),val_propres);
end

%% Application de l'algorithme

for ii=1:nb_essais

    if nb_essais>1
        cd(basepath)
        mkdir(num2str(ii)) %Création d'un nouveau dossier par essai pour sauvegarde
    end

    Tidx=zeros(size(data_classif,1),nb_c-1);
    recap=zeros(nb_c,nb_c-1);

    disp('****')
    disp(['Boucle #' num2str(ii) ' :'])
    disp(' ')
  
for i=1:nb_c-1
    % Algorithme
    if init_auto=='o'
        [idx,C,D] = kmeans_AS(data_classif,i+1,iter,C_init(1:i+1,:),val_propres);
    else
        [idx,C,D] = kmeans_AS(data_classif,i+1,iter,'uniform',val_propres);
    end
    
    % Critères de validations
    [Dij,elim]=dist_inter(D,idx);
    CoefDB=davies_bouldin(Dij,elim);
    [Si,MatSi,KSi]=silhouette(data_classif,idx,val_propres,matdist);
        
    % Affichage
    disp(['k=',num2str(i+1),' : DB=',num2str(CoefDB,'%10.3f'),' - Si=',num2str(Si,'%10.3f')])
    
    % Sauvegarde
    if nb_essais>1
        cd([basepath '\' num2str(ii)]);
    end
    save_c=['save X_',num2str(i+1),'cl ','C D Dij KSi MatSi idx CoefDB Si']; 
    eval(save_c);

    % Un fichier recap et Tidx par essai
    for jj=1:i+1
        recap(jj,i)=size(find(idx==jj),1);
    end
    Tidx(:,i)=idx;
    
    optim_DB(i,ii)=CoefDB;
    optim_SI(i,ii)=Si;
end

if nb_essais>1
cd([basepath '\' num2str(ii)]);
end
save Tidx Tidx
save recap recap
cd(basepath)

[crit_min, nb_classes_retenu]=min(optim_DB(:,ii));
[crit_min2, nb_classes_retenu2]=max(optim_SI(:,ii));

nb_classes_retenu=nb_classes_retenu+1; %car on commence le calcul pour 2 classes au minimum
nb_classes_retenu2=nb_classes_retenu2+1;

disp(' ')
disp(['Nb de classes optimal. DB : ' num2str(nb_classes_retenu) ' - SI : ' num2str(nb_classes_retenu2)])
disp(' ')

end

%% Visualisation de la solution (si un seul essai)

if nb_essais==1
    input_log=['Nombre de classes optimal : ',num2str(nb_classes_retenu)];
    log_essai=str2mat(log_essai,input_log);
    clear input_log

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Construction de la matrice renseignant sur le nombre de signaux   %
    % par classe de chaque classification - les lignes correspondent    %
    % au n° de classe, les colonnes aux classifications                 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('Souhaitez-vous afficher la matrice renseignant les nombres de signaux')
    valid=input('de chaque classe [o/n] ?','s');
    disp(' ')
    if valid=='o' || valid=='y';
    fprintf(2,'***** Construction de la matrice indiquant les populations de classes ******')
    disp(' ') 
    disp(recap)
    end

    disp(' ')
    fprintf(2,'***** Visualisation de la classification ******')
    disp(' ')
    disp(' ')
    disp('Indiquer le nombre de classes pour lequel vous souhaitez charger')
    nb_class=input('la classification (voir matrice ci-dessus) [nombre optimal] ?');
    if isempty(nb_class), nb_class=nb_classes_retenu; end
    text_nb_class=num2str(nb_class);
    chargement_donnees_analysees=['load(''X_' text_nb_class 'cl'')'];
    eval(chargement_donnees_analysees)
    clear reponse_DB chargement_donnees_analysees nb_c
    % Affichage du nombre de signaux de chaque classe
   for i=1:1:nb_class
        nb_c=i;
        [count] = Calc(idx,nb_c);
        text_count=num2str(count);
        text_nb_c=num2str(nb_c);
        comptage=['La classe n°',text_nb_c,' comporte ',text_count,' signaux'];
        disp(comptage)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Construction d'une matrice résultat et d'une matrice par classe    %
    % Les 18 premières colonnes correspondent aux 18 descripteurs        %
    % calculés précédemment. Puis, x(position), temps, idx.              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    index=1;
    s=size(matrice_b1,2);
    for i=1:1:size(matrice_b1,2)
          if matrice_b1(1,i)==1
          matrice_b(1,i)=matrice_b2(1,index);
          index=index+1;
          else
          matrice_b(1,i)=matrice_b1(1,i);
          end
    end

    %%%%
    %%%
    %
    if nb_param==0
    matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx];
    elseif nb_param==1
    matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3)];
    elseif nb_param==2
    matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3:4)];
    end


    donnees_exclues=[descripteurs_filtres(find(matrice_b~=1),:),matrice_localisee_reduite(find(matrice_b~=1 ),1:nb_param+2)];
    save donnees_exclues donnees_exclues
    prct=(size(donnees_exclues,1)/(size(donnees_exclues,1)+size(matrice_finale,1)))*100;

    input_log=['Pourcentage de données exclues : ',num2str(prct)];
    log_essai=str2mat(log_essai,input_log);
    clear prct

    for i=1:1:nb_class
        a=num2str(i);
        recup=['Classe_',a,'=[matrice_finale(find(idx==i),:)];'];
        eval(recup)
        moy=['Moy_',a,'=mean(Classe_',a,');'];
        eval(moy)
        clear moy recup
    end
    disp(' ')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Tracé des clusters dans l'espace réel                              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fprintf(2,'***** Visualisation des clusters dans l''espace reel ******')
    disp(' ')
    disp(' ')
    disp('Quels descripteurs souhaitez-vous utiliser pour tracer les graphes ?');
    selection_descripteurs2=input('Les entrer entre crochets (ex: [2 4 10 13 14 18]) :'); 
    % Procédure de tracé
    nb_d=size(selection_descripteurs2,2);
    tailleA=int8(ceil(sqrt((nb_d*(nb_d-1))/2)+1));
    tailleB=int8(ceil(((nb_d*(nb_d-1))/2))/tailleA);
    ref_graphe=1;
    figure;
    for ref_composante=1:nb_d-1;
        ref_comp_2=ref_composante+1;
        axe1=selection_descripteurs2(ref_composante);
        [axis1]=intitule(axe1);
        while ref_comp_2<nb_d+1;
              axe2=selection_descripteurs2(ref_comp_2);
              [axis2]=intitule(axe2);
              locate_subplot=['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(ref_graphe) ')'];
              eval(locate_subplot);
                for i=1:1:nb_class
                    if i==1
                        gener_graph=['Classe_',num2str(i),'(:,',num2str(axe1),'),Classe_',num2str(i),'(:,',num2str(axe2),'),''.''']; 
                    else
                        gener_graph=[gener_graph,',Classe_',num2str(i),'(:,',num2str(axe1),'),Classe_',num2str(i),'(:,',num2str(axe2),'),''.'''];
                    end
                end
                gener_graphe=['plot(',gener_graph,'); xlabel(''',axis1,'''), ylabel(''',axis2,''')'];
                eval(gener_graphe);
                ref_graphe = ref_graphe + 1;
                ref_comp_2=ref_comp_2+1;      
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Tracé des silhouettes de chaque classe                             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    clear tailleA tailleB ref_graph
    tailleA=int8(ceil(sqrt(max(idx))));
    tailleB=int8(ceil(max(idx)/tailleA));
    figure;
    for i=1:1:max(idx)

        TxtSil=['Silh(:,1)=MatSi(find(idx==',num2str(i),'),1);'];
        eval(TxtSil) 
        clear TxtSil

        locate_subplot=['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(i) ')'];
        eval(locate_subplot);
        hist(Silh,100); xlabel(['Classe ',num2str(i)]); ylabel('Nombre de signaux cumulés'); xlim([-1 1]);


    clear Silh
    end

    clear tailleA tailleB selection_descripteurs2 s save_c ...
          txt_nb gener_graph gener_graphe locate_subplot input_log text_nb_class axe1 axe2 ...
          axis1 axis2 m compt text_nb_c text_limite text_i text_duree text_db text_count ...
          selection_descripteur resultat_db reponse_limite reponse_duree ref_graphe i j ...
          index iter comptage matrice_b1 matrice_b2 count n nb_d filtr ref_comp_2 ...
          ref_composante nb_c a donnees descript matrice_localisee_reduite CP_correlation ...
          D Dij Parametres_normalises val_propres descripteurs_filtres donnes_representatives ...
          data_classif donnees_standardisees grandeurs_non_correlees ...
          matrice_correlation pourcent_explication valeurs_propres donnees_representatives Si axis ...
          elim 

end

%% Sauvegarde

cd(basepath)
save log_essai log_essai
save optim_DB optim_DB;
save optim_SI optim_SI; 

disp('*****    Analyse terminée    *****')
clear Tidx 
duree=toc;
text_duree=num2str(duree);
reponse_duree=['Temps d''exécution du programme: ', text_duree, ' s'];
disp(reponse_duree)
clear text_duree reponse_duree duree 
