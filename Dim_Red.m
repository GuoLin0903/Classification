%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Dimensionality reduction                      %
%                           (Version 1.1)                            %
%                                                                    %
%                                                                    %
%           Emmanuel MAILLET, Doctoral Student (2009/2012)           %
%                           (Version 1.1)                            %
%                      [Algorithm optimisation]                      %
%                                                                    %
%             Arnaud SIBIL, Doctoral Student (2007/2010)             %
%                           (Version 1.0)                            %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%---------------------------------------------------------------------
% Donn�es sauvegard�es dans fichier postACP :
%
%   Descripteurs choisis :
%       desc_graphe (trac� des graphes de contr�le)
%       desc_ln (application du ln)
%       desc_dendro (trac� du dendrogramme)
%       desc_noncorr (non-corr�l�s choisis pour ACP)
%
%   Matrices de donn�es : (ordre chronologique de calcul)
%       data_loc (donn�es localis�es initiales, n x 14)
%       descript_ini (descripteurs uniquement, n x 18 � 20)
%       descript (apr�s filtrage dans base des descripteurs)
%       descript_n (valeurs normalis�es)
%       descript_noncorr (retenus apr�s dendrogramme)
%       descript_preACP (valeurs standardis�es)
%       descript_postACP (dans base des CP)
%       data_classif_nf (n x CP retenues, avant filtrage)
%       data_classif (apr�s filtrage dans base des CP, pr�tes pour classif)
%       data_loc_f (donn�es localis�es apr�s filtrages, nf x 14)
%
%   R�sultats de l'ACP :
%       ACP_R (matrice de corr�lation)
%       ACP_Vec_propres (vecteurs propres base CP)
%       ACP_Val_propres (valeurs propres base CP)
%       ACP_explication (pourcentage cumul� d'explication des CP)
%
%   Autres :
%       ind_filt (indices restants de matrice initiale apr�s filtrages
%       val_propres (valeurs propres des CP retenues)
%       log_dimred (fichier journal)
%
%--------------------------------------------------------------------- 

disp(' ')
fprintf(2,'***** Proc�dure de r�duction de la dimensionnalit� *****')
disp(' ')

%% Calcul des descripteurs / �limination du bruit

log_dimred = []; % Cr�ation du fichier journal


nb_meta_col = 3;      % if +  position    change to 3

switch type_fichier 
    case 'a'
        % AEwin 
        descript_ini = data_loc(:, nb_param+4 : nb_param+12);

        % AEwin 
        disp(' ')
        disp('Souhaitez-vous calculer les 9 descripteurs temporels additionnels ? [o/n]')
        desc_qu = input('(fonctionne ssi les 9 desc temporels AEwin sont les 9 premiers dans la matrice) ', 's');
        if isempty(desc_qu), desc_qu = 'n'; end

    case 'b'
        % 
        % 
        descript_ini = data_loc(:, nb_meta_col+1 : end);

       
        desc_qu = 'n';
end

if desc_qu == 'o'
   
    disp(' ')
    fprintf(2,'***** Calcul des descripteurs 10 � 18 *****')
    disp(' ')
    
    % Suppression des signaux � temps d'extinction nul
    %decay_time=(data_loc(:,nb_param+6)-data_loc(:,nb_param+4));
    %data_loc=data_loc(decay_time>0,:); 
    %clear decay_time

    % Liste des descripteurs
        % 1- temps de montee               10- temps de montee relatif
        % 2- nombre de coups               11- duree/amplitude
        % 3- duree                         12- temps d'extinction
        % 4- amplitude                     13- angle de montee
        % 5- frequence moyenne             14- angle de descente
        % 6- nombre de coups au pic        15- tps de mont./tps de desc.
        % 7- frequence de reverberation    16- energie relative
        % 8- frequence de montee           17- nombre de coup au pic relatif
        % 9- energie absolue               18- amplitude/frequence

    descript_ini(:,10) = descript_ini(:,1)./descript_ini(:,3);
    descript_ini(:,11) = descript_ini(:,3)./descript_ini(:,4);
    descript_ini(:,12) = descript_ini(:,3)-descript_ini(:,1);
    descript_ini(:,13) = descript_ini(:,4)./descript_ini(:,1);
    descript_ini(:,14) = descript_ini(:,4)./descript_ini(:,12);
    descript_ini(:,15) = descript_ini(:,1)./descript_ini(:,12);
    descript_ini(:,16) = descript_ini(:,9)./descript_ini(:,4);
    descript_ini(:,17) = descript_ini(:,6)./descript_ini(:,2);
    descript_ini(:,18) = descript_ini(:,4)./descript_ini(:,5);

    % Si nombre de descripteurs initial > 9
    if type_fichier == 'a' && size(data_loc,2)>nb_param+12
        col_supp = size(data_loc,2)-(nb_param+12);
        descript_ini(:,19:18+col_supp) = data_loc(:,(nb_param+12)+1:(nb_param+12)+col_supp);
        clear col_supp
    end
    if type_fichier == 'b' && size(data_loc,2)>9
        col_supp = size(data_loc,2)-9;
        descript_ini(:,19:18+col_supp) = data_loc(:,10:9+col_supp);
        clear col_supp
    end        

%     % Filtrage des Inf/NaN 
    if type_fichier == 'a'
        [a,~]=find(isinf(descript_ini)==1);
        descript_ini(a,13)=0;
        clear a
    end

    disp(' ')
    disp('-> Descripteurs calcul�s')
end

%% Trac� des fonctions de distribution - Application du ln

switch type_fichier
    case 'a'
        type_desc = 0;
    case 'b'
        type_desc = 1;
end

disp(' ')
histo=input('Souhaitez-vous tracer les fonctions de distributions des descripteurs [o]/[n] ? ', 's');
if isempty(histo), histo='n'; end
if histo=='o' || histo=='y'
    graphe_distrib(descript_ini,type_desc)
end

descript_ln=descript_ini;
disp(' ')
desc_ln=input('Sur quels descripteurs appliquer un ln ([D1 D2 Dn])? ');
if isempty(desc_ln)==0
    descript_ln(:,desc_ln)=log(descript_ini(:,desc_ln));
    if histo=='o' || histo=='y'
        graphe_distrib(descript_ln,type_desc)
    end
end    
clear histo

%% Filtrage des signaux dans base des descripteurs

% Affichage des graphes de contr�le
disp(' ')
desc_graphe=input('Entrer les n� des descripteurs � utiliser pour le trac� ([D1 D2 Dn]) ? ');
if isempty(desc_graphe)==0
    figure
    graphe_cont(descript_ini,desc_graphe,type_desc);
end
    
disp(' ')
filtr=input('Souhaitez-vous r�aliser un filtrage manuel [1] ou automatique [2] des donn�es �loign�es ([0] pas de filtrage) ? ');
if isempty(filtr)==1; filtr=0; end
descript=descript_ln;
ind_filt=cumsum(ones(size(descript,1),1));

% Filtrage manuel
if filtr==1;
    descript_inter=descript_ini;
    filtr2=1;
    nb_filtr=1;
    while filtr2==1
        disp(' ')
        comp_nb=input('Sur quel descripteur filtrer ? ');
        int=input('Intervalle conserv� ? [min max] ');
        
        ind_filt=ind_filt(descript_inter(:,comp_nb)>=int(1) & descript_inter(:,comp_nb)<=int(2),1);
        descript_inter=descript_inter(descript_inter(:,comp_nb)>=int(1) & descript_inter(:,comp_nb)<=int(2),:);
        log_dimred=str2mat(log_dimred,['Filtrage preACP n�' num2str(nb_filtr) ' sur Desc ' num2str(comp_nb)]);
        log_dimred=str2mat(log_dimred,['Intervalle conserv� : [' num2str(int(1)) '; ' num2str(int(2)) ']']);
        nb_filtr=nb_filtr+1;
        % Nouveau trac�
        graphe_cont(descript_inter,desc_graphe,type_desc);
        
        disp(' ')
        cont=input('Souhaitez-vous r�aliser un nouveau filtrage manuel [o/n] ? ', 's');
        if isempty(cont)==1; cont='n'; end
        if cont=='n'            
            filtr2=0;
        end
    end
    descript=descript_ln(ind_filt,:);
clear filtr2 cont comp_nb int nb_filtr descript_inter  
end

% Filtrage automatique
if filtr==2;
    disp(' ')
    alpha=input('Distance � Q1 ou Q3 ? [2] ');
    if isempty(alpha)==1, alpha=2;end
    nb_desc=input('Nombre de desc singuliers mini pour filtrage ? [1] ');
    if isempty(nb_desc)==1, nb_desc=1;end
    log_dimred=str2mat(log_dimred,['Filtrage automatique - alpha : ' num2str(alpha) ' et k : ' num2str(nb_desc)]);
    i_zer=find(descript(:,1)==0);
    [~,~,ind_filt]=filtrage_moustache(descript,alpha,nb_desc);
    ind_filt=setxor(ind_filt,i_zer);
    descript=descript(ind_filt,:);
        % Nouveau trac�
    if isempty(desc_graphe)==0
        graphe_cont(descript_ini(ind_filt,:),desc_graphe,type_desc);
    end
clear alpha nb_desc
end
clear filtr


%% Trac� du dendrogramme - Choix des descripteurs

descript_n=(descript-repmat(min(descript,[],1),size(descript,1),1))./repmat(max(descript,[],1)-min(descript,[],1),size(descript,1),1);

% Trac� du dendrogramme
disp(' ');
filtre_dendro=input('Souhaitez-vous exclure certains descripteurs du trac� du dendrogramme [o]/[n] ? ', 's');
if isempty(filtre_dendro), filtre_dendro='n'; end
if filtre_dendro=='o' || filtre_dendro=='y';
    disp(' ')
    desc_dendro=input('Entrer les n� des descripteurs � conserver pour le dendrogramme ([D1 D2 Dn]) : ');
else
    desc_dendro=1:size(descript,2);  
end
% z=linkage(squareform(1-abs(corrcoef(descript_n(:,desc_dendro)))),'single');
% figure; [H,T,perm]=dendrogram(z,0,'colorthreshold',0.3);
% set(H,'LineWidth',2)
% xlabel('Descripteurs'); ylabel('1-|r|');
%==========================================================%
% Modified by Lin correspond num of dendrogram 
%==========================================================%
z = linkage(squareform(1-abs(corrcoef(descript_n(:,desc_dendro)))),'single');
lab = cellstr(num2str(desc_dendro(:)));
figure;
[H,T,perm] = dendrogram(z, 0, ...
                        'colorthreshold', 0.3, ...
                        'Labels', lab);   % Only change the labels, not the order.
set(H,'LineWidth',2);
xlabel('Descripteurs'); ylabel('1-|r|');
clear filtre_dendro

% Choix des descripteurs � conserver
disp(' ')
desc_noncorr=input('Entrer les n� des descripteurs explicites � conserver pour l''ACP ([D1 D2 Dn]) : ');
descript_noncorr=descript_n(:,desc_noncorr);


%% ACP

disp(' ')
fprintf(2,'***** Analyse en composantes principales (ACP) ******')
disp(' ')

descript_preACP=zscore(descript_noncorr); % Standardisation

disp(' ')
calcul_CP=input('Souhaitez-vous r�aliser une analyse en composantes principales [o]/[n] ? ','s');
if isempty(calcul_CP),calcul_CP='n'; end

if calcul_CP=='o' || calcul_CP=='y'
    [descript_postACP,ACP_Val_propres,ACP_explication,ACP_Vec_propres,ACP_R]=ACP(descript_preACP);

    % D�termination du nombre de CP � conserver
    disp(' ')
    seuil_representativite=input('Quel est le seuil de repr�sentativit� des CP � conserver (%) [95] ? ');
    if isempty(seuil_representativite), seuil_representativite=95; end

    log_dimred=str2mat(log_dimred,['Seuil de repr�sentativit� (%) : ',num2str(seuil_representativite)]);
    seuil_representativite=seuil_representativite/100;
    ACP_explication=round(100*ACP_explication)/100; % arrondi � 2 chiffres
    limite=find(ACP_explication>=seuil_representativite,1);
    data_classif_nf=descript_postACP(:,1:limite);
    val_propres=ACP_Val_propres(:,1:limite);

    log_dimred=str2mat(log_dimred,['Nombre de composantes principales conserv�es : ',num2str(limite)]);
    disp(' ')
    disp(['->' num2str(limite) ' composantes principales sont conserv�es compte tenu du seuil choisi'])

    clear seuil_representativite limite

    % Trac� des donn�es dans la base des CP
    figure
    graphe_cont(data_classif_nf);
else
    descript_postACP=[];ACP_Val_propres=[];ACP_explication=[];ACP_Vec_propres=[];ACP_R=[];
    
    data_classif_nf=descript_preACP;
    val_propres=ones(1,size(data_classif_nf,2));
end

%% Filtrage des signaux dans base des CP

disp(' ')
filtr=input('Souhaitez-vous r�aliser un filtrage manuel [1] ou automatique [2] des donn�es �loign�es ([0] pas de filtrage) ? ');
if isempty(filtr)==1; filtr=0; end
data_classif=data_classif_nf;
% Filtrage manuel
if filtr==1;
    filtr2=1;
    nb_filtr=1;
    while filtr2==1
        disp(' ')
        comp_nb=input('Sur quelle CP filtrer ? ');
        int=input('Intervalle conserv� ? [min max] ');
        
        ind_filt=ind_filt(data_classif(:,comp_nb)>=int(1) & data_classif(:,comp_nb)<=int(2),1);
        data_classif=data_classif(data_classif(:,comp_nb)>=int(1) & data_classif(:,comp_nb)<=int(2),:);
        log_dimred=str2mat(log_dimred,['Filtrage postACP n�' num2str(nb_filtr) ' sur CP' num2str(comp_nb)]);
        log_dimred=str2mat(log_dimred,['Intervalle conserv� : [' num2str(int(1)) '; ' num2str(int(2)) ']']);
        nb_filtr=nb_filtr+1;
        % Nouveau trac�
        graphe_cont(data_classif);
        
        disp(' ')
        cont=input('Souhaitez-vous r�aliser un nouveau filtrage manuel [o/n] ? ', 's');
        if isempty(cont)==1; cont='n'; end
        if cont=='n'            
            filtr2=0;
        end
    end
clear filtr2 cont comp_nb int nb_filtr
end
% Filtrage automatique
if filtr==2;
    log_dimred=str2mat(log_dimred,'Filtrage automatique ACP');
    [data_classif,ind_filt2]=filtrage_dip(data_classif,val_propres,2);
    ind_filt=ind_filt(ind_filt2);
    % Nouveau trac�
    if calcul_CP=='n',figure, end
    graphe_cont(data_classif);
clear ind_filt2
end
clear filtr calcul_CP


%% Reconstruction de la matrice localis�e avec prise en compte des filtrages
data_loc_f=data_loc(ind_filt,:);


%% Sauvegarde

save postACP desc_dendro desc_graphe desc_ln desc_noncorr...
    data_loc descript_ini descript_ln descript descript_n descript_noncorr...
    descript_preACP descript_postACP data_classif_nf data_loc_f ind_filt ...
    ACP_R ACP_Vec_propres ACP_Val_propres ACP_explication...
    data_classif val_propres log_dimred
