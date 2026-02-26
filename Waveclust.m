%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear outil
disp('***************************************************************************')
disp('*           Classification des données d''émission acoustique              *')         
disp('*                    par la methode des K-Moyennes sur                    *')
disp('*                        coefficents d''ondelette                          *')
disp('***************************************************************************')
disp('')
disp('')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calcul des descripteurs / élimination du bruit                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Calcul de nouveaux descripteurs (18) *****')
disp(' ')
%disp('***** Calcul de nouveaux descripteurs (18) *****')
decay_time=(matrice_localisee(:,nb_param+6) - matrice_localisee(:,nb_param+4));              %calcul du temps d'extinction
matrice_localisee_reduite=matrice_localisee(find(decay_time>0),:); 

%%% matrice_localisee --> matrice_localisee_reduite

%élimination des signaux pour lesquels le temps d'extinction est nul
decay_time=decay_time(find(decay_time>0),:);                            %utilisé pour calculer les descripteurs
% La liste des descripteurs est la suivante:
% 1- temps de montee                   10- temps de montee relatif
% 2- nombre de coups                   11- duree/amplitude
% 3- duree                             12- temps d'extinction
% 4- amplitude                         13- angle de montee
% 5- frequence moyenne                 14- angle de descente
% 6- nombre de coups au pic            15- tps de mont./tps de desc.
% 7- frequence de reverberation        16- energie relative
% 8- frequence de montee               17- nombre de coup au pic relatif
% 9- energie absolue                   18- amplitude/frequence
descripteurs = [ ...
    (matrice_localisee_reduite(:,nb_param+4)) ...
    (matrice_localisee_reduite(:,nb_param+5)) ...
    (matrice_localisee_reduite(:,nb_param+6)) ...
    matrice_localisee_reduite(:,nb_param+7) ...
    matrice_localisee_reduite(:,nb_param+8) ...
    matrice_localisee_reduite(:,nb_param+9) ...
    matrice_localisee_reduite(:,nb_param+10) ...
    matrice_localisee_reduite(:,nb_param+11) ...
    (matrice_localisee_reduite(:,nb_param+12)) ...
    (matrice_localisee_reduite(:,nb_param+4)./matrice_localisee_reduite(:,nb_param+6)) ...
    (matrice_localisee_reduite(:,nb_param+6)./matrice_localisee_reduite(:,nb_param+7)) ...
    (decay_time) ...
    (matrice_localisee_reduite(:,nb_param+7)./matrice_localisee_reduite(:,nb_param+4)) ...
    (matrice_localisee_reduite(:,nb_param+7)./decay_time) ...
    (matrice_localisee_reduite(:,nb_param+4)./decay_time) ...
    (matrice_localisee_reduite(:,nb_param+12)./matrice_localisee_reduite(:,nb_param+7)) ...
    matrice_localisee_reduite(:,nb_param+9)./matrice_localisee_reduite(:,nb_param+5) ...
    (matrice_localisee_reduite(:,nb_param+7)./matrice_localisee_reduite(:,nb_param+8)) ...
    ];
clear decay_time %matrice_localisee
disp(' ')
disp('-> Descripteurs calculés')
% Filtrage des Inf/NaN 
[descripteurs_filtres, matrice_localisee_reduite_filtree]=delete_row_isinf(descripteurs, matrice_localisee_reduite);
clear descripteurs matrice_localisee_reduite
matrice_localisee_reduite=matrice_localisee_reduite_filtree;
clear matrice_localisee_reduite_filtree

%%% descripteurs --> descripteurs_filtres

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transformée en ondellette des formes d'ondes associées             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Application d''une transformée en ondelette sur les formes d''onde associées *****')
disp(' ')
disp(' ')

% choix de l'ondelette analysante parmi la collection proposée par MatLab.
disp('Quelle ondelette souhaitez-vous utiliser pour l''analyse ?');
onde=input('--> haar, dbX, biorX.X, coifX, symX, morl, mexh, meyr ...   ','s');
disp(' ')
input_log=['Ondelette utilisé : ',onde];
log_essai=str2mat(log_essai,input_log);


% choix du type de transformée (continue/discrete)
transf=input('Souhaitez-vous realiser une transformée continue ou discrete [c/d] ?   ','s');
disp(' ')
input_log=['Type de transformée : ',transf];
log_essai=str2mat(log_essai,input_log);
        
        if transf~='c' & transf~='d', transf='d'; end
        if isempty(transf), transf='d'; end

        if transf=='c' 
        level=input('Pour quelle echelle souhaitez-vous réaliser la transformée ?    ','s');
        input_log=['Echelle utilisée : ',level];
        log_essai=str2mat(log_essai,input_log);
        elseif transf=='d'
        level=input('Pour quel niveau de decomposition souhaitez-vous réaliser la transformée ?    ','s');
        input_log=['Niveau de decomposition : ',level];
        log_essai=str2mat(log_essai,input_log);
        disp(' ')
        approche=input('Souhaitez-vous travaillez sur les coefficents d''approximation ou de détail [a/d] ?    ','s');
        if isempty(approche), approche='a'; end
        end
        input_log=['Coefficients utilisés : ',approche];
        log_essai=str2mat(log_essai,input_log);
disp(' ')
disp('Calculs en cours ... ')
disp(' ')

% transformée

comp_wav=0;
k=0;
for i=1:size(matrice_localisee_reduite,1)
        
            % procédure de récupération de l'ondelette à analyser
            % recup. du temps du coup et du canal
    
            tps=num2str(matrice_localisee_reduite(i,2));
            if matrice_localisee_reduite(i,2) < 10
                while size(tps,2)<5
                   tps=[tps,'0']; 
                end
                tps=tps(1:5);
              
            elseif matrice_localisee_reduite(i,2) >9.99999 & matrice_localisee_reduite(i,2)<100
                while size(tps,2)<6
                   tps=[tps,'0']; 
                end
                tps=tps(1:6);
               
            elseif matrice_localisee_reduite(i,2) >99.99999 & matrice_localisee_reduite(i,2)<1000
                while size(tps,2)<7
                   tps=[tps,'0']; 
                end
                tps=tps(1:7);   
                
            elseif matrice_localisee_reduite(i,2) >999.99999 & matrice_localisee_reduite(i,2)<10000
                 while size(tps,2)<8
                   tps=[tps,'0']; 
                 end
                 tps=tps(1:8);
                 
            elseif matrice_localisee_reduite(i,2) >9999.99999 & matrice_localisee_reduite(i,2)<100000
                 while size(tps,2)<9
                   tps=[tps,'0']; 
                 end
                 tps=tps(1:9);
                
            elseif matrice_localisee_reduite(i,2) >99999.99999 & matrice_localisee_reduite(i,2)<1000000
                 while size(tps,2)<10
                   tps=[tps,'0']; 
                 end
                 tps=tps(1:10);
                 
            elseif matrice_localisee_reduite(i,2) >999999.99999 & matrice_localisee_reduite(i,2)<10000000
                 while size(tps,2)<11
                   tps=[tps,'0']; 
                 end
                 tps=tps(1:11);
                 
            elseif matrice_localisee_reduite(i,2) >9999999.99999 & matrice_localisee_reduite(i,2)<100000000
                 while size(tps,2)<12
                   tps=[tps,'0']; 
                 end
                 tps=tps(1:12);
               
                                                 
            end 
            
            tps2=tps;
            
            for j=1:1:size(tps2,2)
                if tps2(j)=='.'
                   tps2(j)='_';
                end
            end
            canal=num2str(matrice_localisee_reduite(i,nb_param+3));
        
           % ouverture du fichier texte, recuperation du signal si la forme d'onde est disponible
        
            eval(['fid=fopen(''',nom_fichier,'_',canal,'_',tps,'.txt'');']) 
            if fid==-1
            matrice_a(1,i)=0;      
           
            end
            if fid>2 
            matrice_a(1,i)=1;    
            fclose(fid);
            comp_wav=comp_wav+1;
            eval(['load ',nom_fichier,'_',canal,'_',tps,'.txt;']);
            eval(['signal_temp=',nom_fichier,'_',canal,'_',tps2,';']);
            eval(['clear ',nom_fichier,'_',canal,'_',tps2,';']);
            %%%% normalisation de l'intensité du signal
            signal=signal_temp(250:450)/max(signal_temp); 
            clear signal_temp
            %%%
            l_s=length(signal);
            
                    % Selection de la procédure de transformation,
                    % transformation et remplissage de la matrice les
                    % k-moyennes
                    if transf=='c'
                        eval(['c=cwt(signal,',level,',''',onde,''');'])
                        matrice_coeff(k+1,:)=c;
                        k=k+1;
                        clear c
                    elseif transf=='d'
                        eval(['[Coeff,L] = wavedec(signal,',level,',''',onde,''');']);
                            if approche=='a'
                       
                                eval(['c=appcoef(Coeff,L,''',onde,''',',level,');']);
                                c=c';
                                                    
                            elseif approche=='d'
            
                                eval(['c=detcoef(Coeff,L,',level,');']);
                                c=c';           
                                                 
                            end
                        matrice_coeff(k+1,:)=c;
                        matrice_C(k+1,:)=Coeff;
                        matrice_L(k+1,:)=L;
                        k=k+1;
                        clear Coeff L   
                        clear c
                    end          
            end
          
end

%clear h i fid k comp_wav canal signal tps tps2
disp('Transformée effectuée ')
disp(' ')

nbre_coeff=size(matrice_coeff,2);

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1er filtrage des signaux isolés qui pourrait perturber le        %
% dendrogramme et l'ACP                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
% Affiche des graphes de contrôle
disp(['Quels coefficients souhaitez-vous utiliser pour tracer les graphes (max. ',num2str(nbre_coeff),') ?']);
selection_descripteurs=input('Les entrer entre crochets (ex: [1 2 3 4 5]) :'); 
nb_d=size(selection_descripteurs,2);
tailleA=int8(ceil(sqrt((nb_d*(nb_d-1))/2)+1));
tailleB=int8(ceil(((nb_d*(nb_d-1))/2))/tailleA);
ref_graphe=1;
figure;
for ref_composante=1:nb_d-1;
    ref_comp_2=ref_composante+1;
    axe1=selection_descripteurs(ref_composante);
    while ref_comp_2<nb_d+1;
          axe2=selection_descripteurs(ref_comp_2);
          locate_subplot=['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(ref_graphe) ')'];
          eval(locate_subplot);
          gener_graphe=['plot(matrice_coeff(:,',num2str(axe1),'),matrice_coeff(:,',num2str(axe2),'),''.''); xlabel(''',['Coefficient N°',num2str(axe1)],'''), ylabel(''',['Coefficient N°',num2str(axe2)],''')'];
          eval(gener_graphe);
          ref_graphe = ref_graphe + 1;
          ref_comp_2=ref_comp_2+1;
    end
end
% Filtrage
filtr=input('Souhaitez-vous réaliser un filtrage des données éloignées [o/n] ? ', 's');
if isempty(filtr)
    filtr='n'; 
    [m,n]=size(matrice_coeff);
    coeff_filtres=matrice_coeff;
    matrice_b1=ones(1,m);
    nb_filtr=0;
end
if filtr=='o' | filtr=='y';
[m,n]=size(matrice_coeff);
nb_fil=1;
matrice_temp=[];
for i=1:1:m
matrice_temp(i)=1;
end
[matrice_b1,coeff_filtres,nb_filtr,log_essai]=filt_1(matrice_coeff,nb_d,tailleA,tailleB,nb_fil,matrice_temp,selection_descripteurs,log_essai); 
else
[m,n]=size(matrice_coeff);
matrice_b1=ones(1,m);
coeff_filtres=matrice_coeff;
nb_filtr=0;
end
input_log=['Nombre de filtrage avant ACP : ',num2str(nb_filtr)];
log_essai=str2mat(log_essai,input_log);
clear nb_d tailleA tailleB nb_filtr nb_fil ref_composante ref_comp_2

%%% matrice_coeff --> coeff_filtres


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRACE DES HISTOGRAMMES DES DESCRIPTEURS - APPLICATION DU LN        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
histo=input('Souhaitez-vous tracer les distributions des coefficients [o]/[n] ?', 's');
if isempty(histo), histo='n'; end
if histo=='o' | histo=='y';
axe1=1;    
for i=1:1:ceil(nbre_coeff/6)
    figure;
    for j=1:1:6
    locate_subplot=['subplot(3,2,',num2str(j),')'];
    eval(locate_subplot);
    axis=['Coefficient N°',num2str(axe1)];
    hist(coeff_filtres(:,axe1),100); xlabel([axis]); ylabel('Nombre de signaux cumulés'); 
    axe1=axe1+1;      
    end
end

    disp('Sur quels descripteurs appliquer un ln ?')
    applic=input('Les enter entre crochets []    ');
    if isempty(applic), applic=0; end
        if applic~=0
            for i=1:1:size(applic,2)
                coeff_filtres(:,applic(1,i))=log(coeff_filtres(:,applic(1,i)));
            end    
        end

else

    disp('Sur quels descripteurs appliquer un ln ?')
    applic=input('Les enter entre crochets []    ');
    if isempty(applic), applic=0; end
        if applic~=0
            for i=1:1:size(applic,2)
                coeff_filtres(:,applic(1,i))=log(coeff_filtres(:,applic(1,i)));
            end    
        end 
      
end    

clear histo applic


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRACE DU DENDROGRAMME - CHOIX DES DESCRIPTEURS DISCRIMINANTS       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ');
% Parametres_normalises=zscore(descript);                % normalisation des paramètres
for i=1:1:size(descript,2);
    Parametres_normalises(:,i)=(descript(:,i)-min(descript(:,i)))/(max(descript(:,i))-min(descript(:,i)));
end

filtre_dendro=input('Souhaitez-vous exclure certains descripteurs du tracé du dendrogramme [o]/[n] ?', 's');
if isempty(filtre_dendro), filtre_dendro='n'; end
if filtre_dendro=='n'
    figure;
    DEND=dendrog(Parametres_normalises,'cor'); xlabel('Descripteurs'); ylabel('1-r');  
elseif filtre_dendro=='o' | filtre_dendro=='y';
    disp('Entrer les n° des descripteurs à conserver pour le');
    selection_descripteurs_dendro=input('dendrogramme sous forme de vecteur (entre crochets []):');
    Parametres_normalises_filtres=Parametres_normalises(:,selection_descripteurs_dendro);
    figure;
    DEND=dendrog(Parametres_normalises_filtres,'cor'); xlabel('Descripteurs'); ylabel('1-r');  
end
  

disp(' ')
selection_descripteurs=input('Selection du jeu de parametres par defaut [2 4 10 13 14 18]? o/n [n] ', 's');
if isempty(selection_descripteurs), selection_descripteurs='n'; end
if selection_descripteurs=='o' | selection_descripteurs=='y';
    grandeurs_non_correlees=Parametres_normalises(:,[2 4 10 13 14 18]);
    disp('!!! Utilisation des descripteurs par défaut !!!')
    selection_descripteur=[2 4 10 13 14 18];
    input_log=['Paramètres ACP : [2 4 10 13 14 18]'];
    log_essai=str2mat(log_essai,input_log);
else selection_descripteurs=='n';
    selection_descripteurs=input('Entrer les n° des parametres explicites sous forme de vecteur (entre crochets []): \n');
    grandeurs_non_correlees=Parametres_normalises(:,selection_descripteurs);
    input_log=vect2str(selection_descripteurs, 'formatstring', '%1.0f');
    input_log=['Paramètres ACP : ',input_log];
    log_essai=str2mat(log_essai,input_log);
end
clear DEND selection_descripteurs filtre_dendro selection_descripteurs_dendro Parametres_normalises_filtres
disp(' ')

%%% paramètres_normalises --> grandeurs_non_correlees



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ACP                                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Analyse en composantes principales (ACP) ******')
disp(' ')
disp(' ')
[matrice_correlation,CP_correlation,donnees_standardisees,valeurs_propres,pourcent_explication]=ACP(grandeurs_non_correlees);
% La fonction ACP standardise la matrice de données non correlées "grandeurs_non_correlees",
% puis calcule sa matrice de corrélation "matrice_correlation", 
% les composantes principales de "matrice_correlation", 
% les valeurs propres de "matrice_correlation"
% et le pourcentage d'explication de la variance par les premières composantes principales.
% matrice_correlation : matrice de corrélation
% CP_correlation : vecteurs propres (composantes principales)
% donnees_standardisees : données standardisées exprimées dans la base des vecteurs propres
% valeurs_propres : valeurs propres
% pourcent_explication(i) : pourcentage d'explication de la variance totale par les premiers vecteurs propres
disp(' ')
seuil_representativite=input('Quel est le seuil de représentativité des données à conserver (%) [95 %] ? ');
if isempty(seuil_representativite), seuil_representativite=95; end
input_log=['Seuil de représentativité (%) : ',num2str(seuil_representativite)];
log_essai=str2mat(log_essai,input_log);
seuil_representativite=seuil_representativite/100; % convertion pourcent -> decimal
% scan de l'explication pour trouver le nombre de valeurs propres a traiter
limite=find(pourcent_explication > seuil_representativite, 1);
text_limite=num2str(limite);
reponse_limite=['->', text_limite, ' composantes principales sont conservées compte tenu du seuil choisi'];
disp(' ')
disp(reponse_limite)
disp(' ')
donnees_representatives=donnees_standardisees(:,1:limite);
correlations=valeurs_propres(:,1:limite);
 % trace des donnees dans l'espace des directions principales
taille1=int8(ceil(sqrt((limite*(limite-1))/2)+1));
taille2=int8(ceil(((limite*(limite-1))/2))/taille1);
ref_graphe=1;
figure;
for ref_composante=1:limite-1;
    ref_comp_2=ref_composante+1;
    while ref_comp_2<limite+1;
            locate_subplot=['subplot(' num2str(taille2) ',' num2str(taille1) ',' num2str(ref_graphe) ')'];
            eval(locate_subplot);
            gener_graphe=['plot(donnees_representatives(:,' num2str(ref_composante) '), donnees_representatives(:,' num2str(ref_comp_2) '), ''.k''); xlabel(''CP', num2str(ref_composante), '''), ylabel(''CP' num2str(ref_comp_2),''')'];
            eval(gener_graphe);
            ref_graphe = ref_graphe + 1;
            ref_comp_2=ref_comp_2+1;
     end
end
clear tailleX tailleY ref_graphe ref_composante ref_comp2
input_log=['Nombre de composantes principales conservées : ',num2str(limite)];
log_essai=str2mat(log_essai,input_log);
clear seuil_representativite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filtrage des données isolées restantes pouvant perturber la classification %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
filtr=input('Souhaitez-vous réaliser un filtrage des données éloignées [o/n] ? ', 's');
if isempty(filtr)
    filtr='n'; 
    [m,n]=size(donnees_representatives);
    donnees_reprsentatives_filtrees=donnees_representatives;
    matrice_b2=ones(1,m);
    nb_filtr=0;
end
if filtr=='o' | filtr=='y';
[m,n]=size(donnees_representatives);
nb_fil=1;
matrice_temp=[];
for i=1:1:m
matrice_temp(i)=1;
end
[matrice_b2,donnees_representatives_filtrees,nb_filtr,log_essai]=filtrage_1(donnees_representatives,limite,taille1,taille2,nb_fil,matrice_temp,log_essai); 
else
[m,n]=size(donnees_representatives);
donnees_representatives_filtrees=donnees_representatives;
matrice_b2=ones(1,m);
nb_filtr=0;
end
disp(' ') 
disp(' ')
input_log=['Nombre de filtrage après ACP : ',num2str(nb_filtr)];
log_essai=str2mat(log_essai,input_log);
clear nb_d taille1 taille2 tailleX tailleY nb_fil nb_filtr ref_composante ref_comp_2 limite



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% K-Moyennes                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(2,'***** Classification par les K-Moyennes ******')
%disp('***** Classification par les K-Moyennes ******')
disp(' ')
disp(' ') 
nb_c=input('Pour quel nombre de classes maximum souhaitez-vous réaliser une classification ? [10]');
if isempty(nb_c), nb_c=10; end
disp(' ') 
iter=input('Combien d''itérations souhaitez-vous ? [15]');
if isempty(iter), iter=15; end
disp(' ') 
input_log=['Nombre de classes max. : ',num2str(nb_c)];
log_essai=str2mat(log_essai,input_log);
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


% Application de l'algorithme
for i=1:1:nb_c-1
    [idx,C,D] = kmeans_MM(donnees_representatives_filtrees,i+1,iter,'uniform',correlations);
     [Dij,elim]=dist_inter(D,idx);
    CoefDB=davies_bouldin(Dij,elim);
    [Si,MatSi,KSi]=silhouette(donnees_representatives_filtrees,idx,correlations);
    text_i=num2str(i+1);
    
    text_db=num2str(CoefDB);
    text_si=num2str(Si);
    resultat_db=['Pour ',text_i,' classes, DB=',text_db,', Si=',text_si,''];
    disp(resultat_db)
    
    clear text_si
    
    
    save_c=['save X_',text_i,'cl'];
    eval(save_c);
    if i==1
        optimisation_nb_classesDB=[CoefDB];
        optimisation_nb_classesSI=[Si];
        Tidx=idx;
    else
        optimisation_nb_classesDB= [optimisation_nb_classesDB, CoefDB];
        optimisation_nb_classesSI= [optimisation_nb_classesSI, Si];
        Tidx=[Tidx,idx];
    end
save optimisation_nb_classesDB optimisation_nb_classesDB;
save optimisation_nb_classesSI optimisation_nb_classesSI;
save Tidx Tidx;
nb_k=nb_c;
end
text_nb_c=num2str(nb_c);
disp(' ')
reponse_nb_c=['-> Classification effectuée pour K=2 à K=',text_nb_c,' classes'];
clear text_nb_c
disp(reponse_nb_c)
clear reponse_nb_c
disp(' ')
% Recherche de la meilleur solution
disp('-> Recherche de la meilleure classification... ')
disp(' ')


if critere==1
    [DB_mini, nb_classes_retenu]=min(optimisation_nb_classesDB);
elseif critere==2
    [DB_mini, nb_classes_retenu]=max(optimisation_nb_classesSI);
end

nb_classes_retenu=nb_classes_retenu + 1; %car on commence le calcul pour 2 classes au minimum
text_nb_classes_retenu=num2str(nb_classes_retenu);
reponse_DB=['Le nombre de classes optimal est : ' text_nb_classes_retenu];
disp(reponse_DB)
input_log=['Nombre de classes optimal : ',num2str(nb_classes_retenu)];
log_essai=str2mat(log_essai,input_log); 
save log_essai log_essai
clear reponse DB text_nb_classes_retenu log_essai clear input_log
disp(' ')

[Passage]=split(Tidx,nb_k);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construction de la matrice renseignant sur le nombre de signaux   %
% par classe de chaque classification - les lignes correspondent    %
% au n° de classe, les colonnes aux classifications                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Souhaitez-vous afficher la matrice renseignant les nombres de signaux')
valid=input('de chaque classe [o/n] ?','s');
disp(' ')
if valid=='o' | valid=='y';
fprintf(2,'***** Construction de la matrice indiquant les populations de classes ******')
disp(' ')
recap=zeros(nb_c,nb_c-1);
for i=2:1:nb_c
    txt_nb=num2str(i);
    compt=['load(''X_',txt_nb,'cl'')'];
    eval(compt);
    for j=1:1:i+1
        [count] = Calc(idx,j);
        recap(j,i)=count;
    end 
end
disp(recap)
end
clear valid count



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


index=1;
for i=1:1:size(matrice_a,2)
    if matrice_a(1,i)==1
      matrice_a(1,i)=matrice_b(1,index);
      index=index+1;
    end 
   
    
    
end
clear index


%%%%
%%%
%
if nb_param==0
matrice_finale=[descripteurs_filtres(find(matrice_a),:),matrice_localisee_reduite(find(matrice_b),1:2),idx];
elseif nb_param==1
matrice_finale=[descripteurs_filtres(find(matrice_a),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3)];
elseif nb_param==2
matrice_finale=[descripteurs_filtres(find(matrice_a),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3:4)];
end


donnees_exclues=[descripteurs_filtres(find(matrice_b~=1),:),matrice_localisee_reduite(find(matrice_b~=1 ),1:nb_param+2)];
save donnees_exclues donnees_exclues
prct=(size(donnees_exclues,1)/(size(donnees_exclues,1)+size(matrice_finale,1)))*100;

input_log=['Pourcentage de données exclues : ',num2str(prct)];
log_essai=str2mat(log_essai,input_log);
clear prct
%
%%%
%%%%

for i=1:1:nb_class
    a=num2str(i);
    recup=['Classe_',a,'=[matrice_finale(find(idx==i),:)];'];
    eval(recup)
    moy=['Moy_',a,'=mean(Classe_',a,');'];
    eval(moy)
    clear moy recup
end
disp(' ')

%
%%%   idem reconstrcution des classes en coeff d'ondelette
%%%%%
matrice_coefficients=coeff_filtres(find(matrice_b2),:);
for i=1:1:nb_class
    a=num2str(i);
    recup=['Classe_coeff',a,'=[matrice_coeff(find(idx==i),:)];'];
    eval(recup)
    moy=['Moy_coeff',a,'=mean(Classe_coeff',a,');'];
    eval(moy)
    clear moy recup
end
clear matrice_coefficients


%
%%%   Reconstruction de l'ondelette moyenne de chaque classe
%%%%

C=matrice_C(find(matrice_b),:);
L=matrice_L(1,:);


for i=1:1:nb_class
    a=num2str(i);
    X=mean(C(find(idx==i),:));
    Y=L;
    
for j=1:1:str2num(level)
       
   eval(['[X,Y,cA] = upwlev(X,Y,''',onde,''');'])
   
end
    
   eval(['signal_',num2str(i),'=X;']);
    

clear X Y
end

clear matrice_C matrice_L cA C L


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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tracé de la forme d'onde moyenne de chaque classe                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear tailleA tailleB ref_graph
tailleA=int8(ceil(sqrt(max(idx))));
tailleB=int8(ceil(max(idx)/tailleA));
figure;
for i=1:1:max(idx)
     
    eval(['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(i) ');']);
    eval(['plot(signal_',num2str(i),')'])
    title(['Classe ',num2str(i)]); xlabel('Temps (µs)'); ylabel('Signal (µV)');


end




clear tailleA tailleB selection_descripteurs2 s save_c ...
      txt_nb gener_graph gener_graphe locate_subplot input_log text_nb_class axe1 axe2 ...
      axis1 axis2 m compt text_nb_c text_limite text_i text_duree text_db text_count ...
      selection_descripteur resultat_db reponse_limite reponse_duree ref_graphe i j ...
      index iter comptage matrice_b1 matrice_b2 count n nb_d filtr ref_comp_2 ...
      ref_composante nb_c a donnees descript matrice_localisee_reduite CP_correlation ...
      D Dij Parametres_normalises correlations descripteurs_filtres donnes_representatives ...
      donnees_representatives_filtrees donnees_standardisees grandeurs_non_correlees ...
      matrice_correlation pourcent_explication valeurs_propres donnees_representatives ...
      ans approche canal comp_wav elim fid tps tps2 transf k l_s level nbre_coeff Si signal

load log_essai



disp('*****    Analyse terminee    *****')
clear Tidx 
duree=toc;
text_duree=num2str(duree);
reponse_duree=['Temps d''execution du programme: ', text_duree, ' s'];
disp(reponse_duree)
clear text_duree reponse_duree duree 
