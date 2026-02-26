%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Data Clustering  WEASEL                      %
%               Wavelet Enhanced AcouStic Emission Lab.              %
%                      Version 1.1 - December 2010                   %
%                                                                    %
%   All-in-one programm allowing the folling clustering processes :  %
%                                                                    %
%          --> Classical K-Means algorithm on A.E. parameters        %
%          --> Kohonen Map                                           %
%          --> Validity index optimisation with Genetic Algorithm    %
%                                                                    %
%           Emmanuel MAILLET, Doctoral Student (2009/2012)           %
%                           (Version 1.1)                            %
%                                                                    %
%             Arnaud SIBIL, Doctoral Student (2007/2010)             %
%                           (Version 1.0)                            %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%             K-Means core developped by Mariette Moevus             % 
%                    Doctoral student - 2003/2007                    %
%                                                                    %
%              Kohonen Map developped by Stéphane Huguet             %
%                    Doctoral student - 1999-2002                    %
%                                                                    %
%               Further improvements by Ludovic Pinier               %
%                  Postdoctoral fellow - 2008/2009                   %
%                                                                    %


clear all
clc   %nettoyage de la fenetre de commande
disp('***************************************************************************')
disp('*         Classification des données d''émission acoustique WEASEL         *')
disp('*             Wavelet Enhanced AcouStic Emission Laboratory               *')
disp('*                                                                         *')
disp('*   --> K-Moyennes (sur paramčtres EA ou coefficients d''ondelette)        *')
disp('*   --> Optimisation du critčre par AG (sur param EA ou coeff d''ondelette)*')
disp('*   --> Carte auto-organisatrice (Kohonen)                                *')
disp('***************************************************************************')
disp('                                      version pour Matlab2008b et suivantes')
disp(' ')


%% Chargement du fichier de données

fprintf(2,'***** Chargement du fichier de données *****')
disp(' ')
disp(' ')
type_fichier = input('Type de fichier de données ŕ charger [a : AEwin ; b : autre] : ', 's');

switch type_fichier
    case 'a'
        disp(' ')
        format_fichier = input('Format du fichier de données [t : .txt ; m : .mat] : ', 's');

        switch format_fichier 
            case 't'
            disp(' ')
            nom_fichier = input('Taper le nom du fichier ŕ traiter (sans extension) : ', 's');

            eval(['load ',nom_fichier,'.TXT -ascii']);
            eval(['matrice = ', nom_fichier, '(:,:) ;']);

            case 'm'
            [nom_fichier,rep_fichier] = uigetfile('*.mat','Sélectionnez le fichier de données');
            matrice = importdata([rep_fichier nom_fichier]);

        end
        log_essai = str2mat(['Nom du fichier : ',nom_fichier]);
        clear nom_fichier rep_fichier

        disp(' ')
        nb_param = input('Entrer le nombre de paramétriques présentes dans le fichier : [2] ');
        if isempty(nb_param) == 1, nb_param = 2; end
        log_essai = str2mat(log_essai,['Nombre de paramétriques : ',num2str(nb_param)]);


        %% Localisation et filtrage aux extrémités

        disp(' ')
        chx_filtr = input('Souhaitez-vous réaliser une localisation des données ? [o/n] ', 's');
        if isempty(chx_filtr), chx_filtr = 'n'; end
        if chx_filtr == 'o' || chx_filtr == 'y';
            fprintf(2,'***** Procédure de localisation *****')
            [data_loc,log_essai]=localize(matrice,log_essai,nb_param); 
            log_essai = str2mat(log_essai,'Procédure de localisation : OUI'); 
        else data_loc = matrice;
            log_essai = str2mat(log_essai,'Procédure de localisation : NON'); 
        end           
        clear matrice chx_filtr


        %% Réduction du jeu de données

        disp(' ')
        reduc = input('Souhaitez-vous effectuer une réduction des données d''entrée ? [o/n] ', 's');
        if isempty(reduc), reduc = 'n'; end
        if reduc == 'o' || reduc == 'y'
            nbre_reduc = input('Proportion de signaux ŕ conserver 1/X ? [X=3] ');
            if isempty(nbre_reduc), nbre_reduc=3; end

            ligne = 1;
            i = 1;
            while i <= size(data_loc,1) 
               temp_mat(ligne,:) = data_loc(i,:);
               i = i+nbre_reduc;
               ligne = ligne+1;
            end    
        clear data_loc
        data_loc = temp_mat;
        clear nbre_reduc ligne temp_mat i
        end    
        clear reduc

        
    case 'b'
        disp(' ')
        disp('Vous avez sélectionné "Autre".')
        dimred_qu = input('Souhaitez-vous lancer la procédure de réduction de la dimensionnalité ? [o/n] ', 's');
        
        if dimred_qu == 'o'
            % Chargement du fichier de données
            [FileName,PathName] = uigetfile('*.mat','Sélectionnez le fichier de données');
            data_loc = importdata([PathName FileName]);
        else
            % Chargement du fichier postACP
            [FileName,PathName] = uigetfile('*.mat','Sélectionnez le fichier PostACP');
            postACP = importdata([PathName FileName]);

            data_classif = postACP.data_classif;
            val_propres = postACP.val_propres;
%             descript_ini = postACP.descript_ini;
%             ind_filt = postACP.ind_filt;
        end
        clear FileName PathName
 
end


%% Réduction de la dimensionnalité (sous-prog Dim_Red)

if type_fichier == 'a'  || dimred_qu == 'o'
    % Lancement du programme Dim_Red
    Dim_Red
end


%% Lancement de la classification
disp(' ')
disp('Quel outil de classification souhaitez-vous utiliser ?')
disp(' ')
disp('[1] K-Moyennes classiques (mŕj requise), [2] AG, [3] K-moy sur ondelettes (mŕj requise)'); 
outil = input('[4] AG sur ondelettes (mŕj requise), [5] Carte de Kohonen (mŕj requise)  ', 's');
disp(' ')
disp(' ')

if outil=='1'
    KMeans_classical
    log_essai=str2mat(log_essai,'Méthode utilisée : K-Moyennes classiques');
elseif outil=='2'
    GAclust
    log_essai=str2mat(log_essai,'Méthode utilisée : AG ');
elseif outil=='3'
    Waveclust
    log_essai=str2mat(log_essai,'Méthode utilisée : K-Moyennes appliquées aux coefficients d''ondelettes');
elseif outil=='4'
    Waveclust_ga
    log_essai=str2mat(log_essai,'Méthode utilisée : AG sur coefficients d''ondelettes');
elseif outil=='5'
    Kohonen_main
    log_essai=str2mat(log_essai,'Méthode utilisée : Carte de Kohonen');     
end