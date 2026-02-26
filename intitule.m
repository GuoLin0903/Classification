%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2012                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [axis]=intitule(axe)

if axe > 24
    axis = num2str(axe);
else
    switch axe
        case 1
            axis='Temps de montée, \mus (1)';
        case 2
            axis='Nombre de coups (2)';
        case 3
            axis='Durée, \mus (3)';
        case 4
            axis='Amplitude, dB (4)';
        case 5
            axis='Fréquence moyenne, kHz (5)';
        case 6
            axis='Nombre de coups au pic (6)';
        case 7
            axis='Fréquence de reverberation, kHz (7)';
        case 8
            axis='Fréquence de montée, kHz (8)';
        case 9
            axis='Energie, attoJ (9)';
        case 10
            axis='Temps de montée relatif (10)';
        case 11
            axis='Durée/Amplitude, \mus/dB (11)';
        case 12
            axis='Temps d''extinction, \mus (12)';
        case 13
            axis='Angle de montée, dB/\mus (13)';
        case 14
            axis='Angle de descente, dB/\mus (14)';
        case 15
            axis='Tps de montée / tps de descente(15)';
        case 16
            axis='Energie relative, attoJ/dB (16)';
        case 17
            axis='Nombre de coups au pic relatif (17)';
        case 18
            axis='Amplitude/fréquence, dB/kHz (18)'; 
        case 19
            axis='Puissance partielle 1, % (19)'; % axis='Position (mm)(19)';
        case 20
            axis='Puissance partielle 2, % (20)'; % axis='Temps (s)(20)';
        case 21
            axis='Puissance partielle 3, % (21)'; % axis='N° de classe (21)'; 
        case 22
            axis='Puissance partielle 4, % (22)'; % axis='Paramétrique 1 (22)';          
        case 23
            axis='Barycentre spectral, kHz (23)'; % axis='Paramétrique 2 (23)'; 
        case 24
            axis='Fréquence au pic, kHz (24)'; 
    end    
end

end