%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function [axis]=intitule_WFfeat(axe)
% 
% if axe > 30
%     axis = num2str(axe);
% else
%     switch axe
%         case 1
%             axis='Amplitude, V (1)';
%         case 2
%             axis='Durée, s (2)';
%         case 3
%             axis='Energie, V^2 (3)';
%         case 4
%             axis='Zero-crossing, - (4)';
%         case 5
%             axis='Temps de montée, s (5)';
%         case 6
%             axis='Barycentre temporel, s (6)';
%         case 7
%             axis='Décroissance temporelle, - (7)';
%         case 8
%             axis='Puissance partielle 1, % (8)';
%         case 9
%             axis='Puissance partielle 2, % (9)';
%         case 10
%             axis='Puissance partielle 3, % (10)';
%         case 11
%             axis='Puissance partielle 4, % (11)';
%         case 12
%             axis='Barycentre spectral, Hz (12)';
%         case 13
%             axis='Fréquence au pic, Hz (13)';
%         case 14
%             axis='Etalement, - (14)';
%         case 15
%             axis='Dissymétrie, - (15)';
%         case 16
%             axis='Aplatissement, - (16)';
%         case 17
%             axis='Pente, /Hz (17)';
%         case 18
%             axis='Fréquence de coupure, Hz (18)'; 
%         case 19
%             axis='Etalement (/pic), - (19)'; 
%         case 20
%             axis='Dissymétrie (/pic), - (20)';
%         case 21
%             axis='Aplatissement (/pic), - (21)';  
%         case 22
%             axis='Fréquence d''ouverture, Hz (22)';          
%         case 23
%             axis='Energie du paquet d''ondelette 1, % (23)';
%         case 24
%             axis='Energie du paquet d''ondelette 2, % (24)';
%         case 25
%             axis='Energie du paquet d''ondelette 3, % (25)';
%         case 26
%             axis='Energie du paquet d''ondelette 4, % (26)';
%         case 27
%             axis='Energie du paquet d''ondelette 5, % (27)';
%         case 28
%             axis='Energie du paquet d''ondelette 6, % (28)';
%         case 29
%             axis='Energie du paquet d''ondelette 7, % (29)';
%         case 30
%             axis='Energie du paquet d''ondelette 8, % (30)';
%     end    
% end
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    LIN 31 Features                                 %                       
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = intitule_WFfeat(axe)


switch axe
    case 1
        label = 'S1\_Amp\_dB (1)';
    case 2
        label = 'S1\_Dur\_us (2)';
    case 3
        label = 'S1\_Energy\_V^2 (3)';
    case 4
        label = 'S1\_ZCR\_pct (4)';
    case 5
        label = 'S1\_RiseTime\_us (5)';
    case 6
        label = 'S1\_TempCentroid\_us (6)';
    case 7
        label = 'S1\_alpha (7)';
    case 8
        label = 'S1\_PP2\_1 (8)';
    case 9
        label = 'S1\_PP2\_2 (9)';
    case 10
        label = 'S1\_PP2\_3 (10)';
    case 11
        label = 'S1\_PP2\_4 (11)';
    case 12
        label = 'S1\_FC\_kHz (12)';
    case 13
        label = 'S1\_PF\_kHz (13)';
    case 14
        label = 'S1\_SSpread\_kHz (14)';
    case 15
        label = 'S1\_SSkew (15)';
    case 16
        label = 'S1\_SKurt (16)';
    case 17
        label = 'S1\_SSlope (17)';
    case 18
        label = 'S1\_SRoff\_kHz (18)';
    case 19
        label = 'S1\_SsqrtSpreadP\_kHz (19)';
    case 20
        label = 'S1\_SSkewP (20)';
    case 21
        label = 'S1\_SKurtP (21)';
    case 22
        label = 'S1\_SRon\_kHz (22)';
    case 23
        label = 'S1\_WPE1 (23)';
    case 24
        label = 'S1\_WPE2 (24)';
    case 25
        label = 'S1\_WPE3 (25)';
    case 26
        label = 'S1\_WPE4 (26)';
    case 27
        label = 'S1\_WPE5 (27)';
    case 28
        label = 'S1\_WPE6 (28)';
    case 29
        label = 'S1\_WPE7 (29)';
    case 30
        label = 'S1\_WPE8 (30)';
    case 31
        label = 'S1\_Entropy (31)';
    otherwise
       
        label = sprintf('Desc %d', axe);
end

end
