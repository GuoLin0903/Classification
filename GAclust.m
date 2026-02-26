%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Genetic algorithm-based clustering method optimisation      %
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
disp('*            par la méthode basée sur l''algorithme génétique              *')
disp('*                et optimisant le critère de validation                   *')
disp('***************************************************************************')
disp(' ')


%% Paramètres de l'algorithme

disp(' ')
fprintf(2,'***** Classification par Algorithme Génétique ******')
disp(' ')
disp(' ') 
nb_c=input('Pour quel nombre de classes maximum souhaitez-vous réaliser une classification ? [10] ');
if isempty(nb_c), nb_c=10; end
disp(' ') 
input_log=['Nombre de classes max. : ',num2str(nb_c)];
log_essai=input_log;

popsize=input('Combien d''individus souhaitez-vous créer ? [100] ');
if isempty(popsize), popsize=100; end
disp(' ') 
input_log=['Taille de la population : ',num2str(popsize)];
log_essai=str2mat(log_essai,input_log);

critere=input('Critère optimisé par AG : [1] DB | [2] Si ? ');
if isempty(critere), critere=1; end
disp(' ') 
if critere==1
    log_essai=str2mat(log_essai,'Critère optimisé : Davies et Bouldin');
    elseif critere==2
    critereSI=input('Maximisation de la Silhouette moyenne [1] ou mini [2] ? ');
    log_essai=str2mat(log_essai,'Critère optimisé : Silhouettes',['Critère ' num2str(critereSI)]);
    disp(' ')
end

ponderation = input('Distances pondérées par les valeurs propres : [0] Non | [1] Oui ? ');
disp(' ')
if isempty(ponderation), ponderation=1; end
if ponderation == 0
    val_propres = repmat(1,1,size(data_classif,2));
end

nb_essais=input('Combien de fois souhaitez-vous réaliser la classification ? ');
disp(' ')

%% Préparation

basepath=pwd; %Dossier de base

optim_DB=zeros(nb_c-1,nb_essais);
optim_SI=zeros(nb_c-1,nb_essais);

% Limites pour centres de classe (0.8 pour éviter centres en périphérie du jeu de données)
Cmin=min(data_classif,[],1); %*0.8
Cmax=max(data_classif,[],1); %*0.8

tic % déclenchement du chronomètre

% Calcul de la matrice de distances entre points pour calcul des Si
disp('Calcul de la matrice de distances entre points...')
disp(' ')

nbsig=size(data_classif,1);
if nbsig < 10000
    matdist=cell(ceil(nbsig/100),100);
    for i=1:nbsig
        li=ceil(i/100);
        co=i-100*(li-1);
        matdist{li,co}=distfun(data_classif,data_classif(i,:),val_propres);
    end
end

limite=size(data_classif,2);

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
    
    % Construction des vecteurs limitant l'espace des coordonnées des centres
    C1=repmat(Cmin,1,i);
    C2=repmat(Cmax,1,i);
      
    % Calcul du nombre de variables (NVars dans fonction ga)  
    nvars=(i+1)*limite;
    nb_cga=i+1;
     
    % Tirage de la population initiale (chaque centre prend les coordonnées d'un signal
    initpop=zeros(popsize,nvars);
        
    for l=1:i+1
        initpop(:,(l-1)*limite+1:l*limite)=data_classif(randi(size(data_classif,1),popsize,1),:);
    end 

    % Réglages des options G.A.
    options=gaoptimset(@ga);
    options=gaoptimset(options,'InitialPopulation',initpop,'PopulationSize',popsize,...
        'EliteCount',2,'CrossoverFraction',0.8,'MutationFcn',@mutationadaptfeasible,...
        'Generations',Inf,'StallGenLimit',40,'TolFun',1.0e-4,...
        'Display','off','PlotFcns',@gaplotbestf); 
    %'Display','final': affiche raison de l'arrêt
    % StallGenLimit & TolFun : arrêt de l'algorithme lorsque la valeur moyenne  du critère évolue d'une valeur inférieure à "TolFun" sur les
        % "StallgenLimit" dernières générations
   
    if critere==1
        [C ~]=ga(@(x)fitness_ga(x,nb_cga,limite,val_propres,data_classif),nvars,[],[],[],[],C1,C2,[],options);
    elseif critere==2
        [C ~]=ga(@(x)fitness_si(x,nb_cga,limite,val_propres,data_classif,critereSI),nvars,[],[],[],[],C1,C2,[],options);
    end
        
    % Construction de la matrice coordonnées des centres à partir du chromosome optimal
    Centres=zeros(i+1,limite);
    index=1;
    for k=1:i+1
        for l=1:limite
            Centres(k,l)=C(1,index);
            index=index+1;
        end    
    end
    clear index
    
    % Détermination de idx et des valeurs des critères pour sol. optimale
    D=distfun(data_classif,Centres,val_propres);
    [E,idx]=min(D,[],2);
    
    [Dij,elim]=dist_inter(D,idx);
    CoefDB=davies_bouldin(Dij,elim);
    
    if nbsig < 10000
        [Si,MatSi,KSi]=silhouette(data_classif,idx,val_propres,matdist); 
    else [Si,MatSi,KSi]=silhouette(data_classif,idx,val_propres);
    end
    
    % Affichage
    disp(['k=',num2str(i+1),' : DB=',num2str(CoefDB,'%10.3f'),' - Si=',num2str(Si,'%10.3f')])
    
    % Sauvegarde
    if nb_essais>1
        if ismac == 0
            cd([basepath '\' num2str(ii)]);
        else
            cd([basepath '/' num2str(ii)]);
        end
    end
    save_c=['save X_',num2str(i+1),'cl ','C Centres D Dij KSi MatSi idx CoefDB Si'];
    eval(save_c);
    cd(basepath)
    
    % Un fichier recap et Tidx par essai
    for jj=1:i+1
        recap(jj,i)=size(find(idx==jj),1);
    end
    Tidx(:,i)=idx;
    
    optim_DB(i,ii)=CoefDB;
    optim_SI(i,ii)=Si;
    
    clear idx Centres D E Dij elim
end

if nb_essais>1
    if ismac == 0
        cd([basepath '\' num2str(ii)]);
    else
        cd([basepath '/' num2str(ii)]);
    end
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

%% Tracé des graphes d'évolution des critères en fonction de k

k=2:nb_c;
figure
subplot(2,1,1)
plot(k,optim_DB,'x')
xlabel('Nombre k de classes de la solution')
ylabel('DB')
subplot(2,1,2)
plot(k,optim_SI,'x')
xlabel('Nombre k de classes de la solution')
ylabel('Silhouette moyenne')


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
    valid=input('de chaque classe [o/n] ? ','s');
    disp(' ')
    if valid=='o' || valid=='y';
    disp(' ')
    disp(recap)
    end
    clear valid
    
    disp(' ')
    fprintf(2,'***** Visualisation de la classification ******')
    disp(' ')
    disp(' ')
    disp('Indiquer le nombre de classes pour lequel vous souhaitez charger')
    nb_class=input('la classification (voir matrice ci-dessus) [nombre optimal] ? ');
    if isempty(nb_class), nb_class=nb_classes_retenu; end
    load(['X_' num2str(nb_class) 'cl'])
       
    % Affichage du nombre de signaux de chaque classe
    for i=1:nb_class
        disp(['La classe n°' num2str(i) ' comporte ' num2str(size(find(idx==i),1)) ' signaux'])
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Tracé des clusters dans l'espace réel                              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    disp(' ')
    fprintf(2,'***** Visualisation des clusters dans l''espace reel ******')
    disp(' ')
    disp(' ')
    desc_graphe2 = input('Entrer les n° des descripteurs à utiliser pour le tracé ([D1 D2 Dn]) ? ');
    
    matdesc = descript_ini(ind_filt,:);
    
    nb_d = size(desc_graphe2,2);
    nb_subplot = nb_d*(nb_d-1)/2;
    tailleA = ceil(sqrt(nb_subplot));
    tailleB = ceil(nb_subplot/tailleA);
    ref_graphe = 1;
    figure;
    for ref_composante = 1:nb_d-1;
        ref_comp_2 = ref_composante+1;
        axe1 = desc_graphe2(ref_composante);
        while ref_comp_2 < nb_d+1;
            axe2 = desc_graphe2(ref_comp_2);
            subplot(tailleB,tailleA,ref_graphe)
            gener_graph = ['matdesc(idx==1,',num2str(axe1),'),matdesc(idx==1,',num2str(axe2),'),''.''']; 
            for i = 2:nb_class
                gener_graph = [gener_graph,',matdesc(idx==',num2str(i),',',num2str(axe1),'),matdesc(idx==',num2str(i),',',num2str(axe2),'),''.'''];
            end
            eval(['plot(',gener_graph,')'])
            switch type_fichier
                case 'a'
                    xlabel(intitule(axe1))
                    ylabel(intitule(axe2))
                case 'b'
                    xlabel(intitule_WFfeat(axe1))
                    ylabel(intitule_WFfeat(axe2))
            end
            ref_graphe = ref_graphe+1;
            ref_comp_2 = ref_comp_2+1;      
        end
    end
    clear tailleA tailleB ref_graph gener_graph axe1 axe2 ref_composante ref_comp_2
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Tracé des silhouettes de chaque classe                             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    tailleA = ceil(sqrt(max(idx)));
    tailleB = ceil(max(idx)/tailleA);
    figure;
    for i = 1:max(idx)
        Silh(:,1) = MatSi(idx==i,1);
        subplot(tailleB,tailleA,i)
        hist(Silh,100);
        xlim([-1 1]);
        xlabel(['Classe ',num2str(i)]); 
        ylabel('Nombre de signaux cumulés'); 
        title(['Silhouette moyenne : ' num2str(mean(Silh))])
        clear Silh
    end
    clear tailleA tailleB
end

%% Sauvegarde

cd(basepath)
save log_essai log_essai
save optim_DB optim_DB;
save optim_SI optim_SI; 

duree=toc;
disp(' ')
fprintf(2,'******    Analyse terminée    ******')
disp(' ')
disp(' ')
disp(['Temps d''exécution du programme: ' num2str(duree) ' s'])

