%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:1:nb_class
    a=num2str(i);
    clr=['clear Classe_',a];
    eval(clr)
    clr=['clear Moy_',a];
    eval(clr)
    clear clr
end
clear KSi
clear nb_class 
disp(' ')
%%%%%%%
disp('Indiquer le nombre de classes pour lequel vous souhaitez ')
nb_class=input('chargé la classification [nombre optimal] ?');
if isempty(nb_class), nb_class=nb_k; end
text_nb_class=num2str(nb_class);
%%%%%%
chargement_donnees_analysees=['load(''X_' text_nb_class 'cl'')'];
eval(chargement_donnees_analysees)
clear reponse_DB chargement_donnees_analysees 
%%%%%%
% Affichage du nombre de signaux de chaque classe
%%%%%%
for i=1:1:nb_class
    nb_c=i;
    [count] = Calc(idx,nb_c);
    text_count=num2str(count);
    text_nb_c=num2str(nb_c);
    comptage=['La classe n°',text_nb_c,' comporte ',text_count,' signaux'];
    disp(comptage)
end
%%%%%%%
% Construction d'une matrice résultat et d'une matrice par classe
%%%%%%
% Les 18 premières colonnes correspondent aux 18 descripteurs calculés
% précédemment. Puis, x(position), temps, idx.

if nb_param==0
matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx];
elseif nb_param==1
matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3)];
elseif nb_param==2
matrice_finale=[descripteurs_filtres(find(matrice_b),:),matrice_localisee_reduite(find(matrice_b),1:2),idx,matrice_localisee_reduite(find(matrice_b),3:4)];
end

for i=1:1:nb_class
    a=num2str(i);
    recup=['Classe_',a,'=[matrice_finale(find(idx==i),:)];'];
    eval(recup)
    moy=['Moy_',a,'=mean(Classe_',a,');'];
    eval(moy)
    clear moy recup
end
%%%%%%
% 
%%%%%%
disp(' ')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tracé des clusters dans l'espace réel                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Visualisation des clusters dans l''espace reel ******')
%disp
disp(' ')
disp(' ')
disp('Quels descripteurs souhaitez-vous utiliser pour tracer les graphes ?');
selection_descripteurs2=input('Les entrer entre crochets (ex: [2 4 10 13 14 18]) :'); 
selection_descripteurs2;
%%%%%%
% Procédure auto de génération des graphes
%%%%%%
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
    hist(Silh,100); xlabel(['Classe ',num2str(i)]); ylabel('Nombre de signaux cumulés'); 
    xlim([-1 1]);
    

clear Silh
end






clear tailleA tailleB selection_descripteurs2 s save_c ...
      txt_nb gener_graph gener_graphe locate_subplot input_log text_nb_class axe1 axe2 ...
      axis1 axis2 m compt text_nb_c text_limite text_i text_duree text_db text_count ...
      selection_descripteur resultat_db reponse_limite reponse_duree ref_graphe i j ...
      index iter comptage matrice_b1 matrice_b2 count n nb_d filtr ref_comp_2 ...
      ref_composante nb_c a donnees descript matrice_localisee_reduite CP_correlation ...
      D Dij Parametres_normalises correlations descripteurs_filtres donnes_representatives ...
      donnees_representatives_filtrees donnees_standardisees grandeurs_non_correlees ...
      matrice_correlation pourcent_explication valeurs_propres donnees_representatives
     
