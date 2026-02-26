%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                    %
%%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%%                        Equipes CERA & ENDV                         %
%%                                2011                                %
%%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% --------------------------------------------------------------------
% function [dataf,res,indf,out_select,outliers]=filtrage(data,a,k)
%
% Filtrage basé sur la distance à Q1 et Q3 (boîte à moustache)
%
% data : données (ln a été appliqué si besoin - voir fonction dend)
% a : défini la distance à Q1 et Q3 au-delà de laquelle une donnée est
%       considérée singulière
% k : si un signal a une valeur singulière sur au moins k descripteurs,
%       alors il est considéré singulier
%
% dataf : données filtrées
% res : récapitulatif des filtrages par desc
% indf : indices des données conservées (dans matrice de départ)
% out_select : indices des données singulières supprimées
% outliers : valeurs singulières
% --------------------------------------------------------------------

function [dataf,res,indf,out_select,outliers]=filtrage_moustache(data,a,k)

%% Filtrage par descripteur

res=cell(8,size(data,2));
indout=[];

for i=1:size(data,2)

    datai=data(:,i);

    % Calcul de la médiane
    med=median(datai);

    % Calcul de Q1, Q3 et du IQR (InterQuartile Range)
    datasort=sort(datai);
    Q1=median(datasort(datasort<med));
    Q3=median(datasort(datasort>med));
    IQR=Q3-Q1;

    % Identification des valeurs singulières
    % Extreme Q1 outliers (x < Q1 - a*IQR)
    indQ1=find(datai<Q1-a*IQR);

    % Extreme Q3 outliers (x > Q3 + a*IQR)
    indQ3=find(datai>Q3+a*IQR);

    indout=[indout;indQ1;indQ3];

    ratio_outliers=100*(length(indQ1)+length(indQ3))/length(datai);

    % Enregistrement des résultats

    res{1,i}=med;
    res{2,i}=Q1;
    res{3,i}=Q3;
    res{4,i}=IQR;
    res{5,i}=a;
    res{6,i}=indQ1;
    res{7,i}=indQ3;
    res{8,i}=ratio_outliers;

    clear indQ1 indQ3
    
end


%% Création de la matrice Outliers

indout=sort(indout);

i=1; j=1;
while i<=length(indout)
    nb_oc(j,1)=indout(i);
    nb_oc(j,2)=length(find(indout(:)==indout(i))); %Nb d'occurences de l'outlier
    i=i+length(find(indout(:)==indout(i)));
    j=j+1;
end

%Outliers conservés seulement si au moins k de leurs descripteurs sont outliers
out_select(:,[1 2])=nb_oc(nb_oc(:,2)>=k,[1 2]); 

outliers=data(out_select(:,1),:);


%% Création de la matrice des données filtrées

indini=cumsum(ones(size(data,1),1));

indf=setdiff(indini,out_select(:,1));

dataf=data(indf,:);