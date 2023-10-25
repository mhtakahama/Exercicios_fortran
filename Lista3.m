clear all; echo off; close all force; clc; format long; %clear another variables
%% Doutorado em Engenharia Mec�nica PPGEM
%Universidade Tecnol�gica Federal do Paran�
%Campus Curitiba
%Aluno: Marcos Takahama
%Professor Paulo Henrique Dias dos Santos
%Disciplina:CFD
%03/10/2020
% Ex_Aula_3_CFD.m
%     Determine o perfil de temperatura de uma barra de a�o (K=25 W/mK) de 1 metro
%     de comprimento com temperaturas prescritas nas extremidades. Na extremidade em
%     x=0, a temperatura vale 150�C e em x=L vale 50�C. Resolva o problema
%     pelos m�todos TDMA, Jacobi, Gauss-Seidel e SOR e compare o tempo
%     computacional entre os m�todos

% Checkpoint = Ponto de debug
%% 1 - Inputs

%input parameters
prompt = {'Valor da Temperatura 1','Valor da Temperatura 2','n�mero de VC','Coef de relaxacao SOR'};
dlg_title = 'Condi��es de Contorno';
num_lines = 1;
defaultans = {'150','50','500','0.5'};
N=50; %this will control the width of the inputdlg
answer = inputdlg(prompt,dlg_title,[1, length(dlg_title)+N],defaultans);
%input

Tp1=str2num(answer{1});
Tp2=str2num(answer{2});
nv=str2num(answer{3});
w=str2num(answer{4});

%% 2-M�todo VF
L = 1.0;
dx = L/nv;
k = 25;
T_est = 25;
erro = 1e-4;
kmax = 8*10^5;

%Estimativa do campo inicial da vari�vel
for i=1:nv
    T(i) = T_est;
end

%C�lculo da malha:
x(1) = 0.5*dx;

for i=2:nv
    x(i) = x(i-1) + dx;
end

% fprintf('Informa��es da Malha')
% x

%C�lculo temperatura atrav�s do MVF
for i=1:nv
    if (i==1)
        Ae(i)=1;
        Aw(i)=0;
        Su(i)=2*Tp1;
        Sp(i)=-2;
        Ap(i)=Ae(i)+Aw(i)-Sp(i);
        
        E(i,i)=Ap(i);
        E(i,i+1)=-Ae(i);
    else if((i>1)&&(i<nv))
            Ae(i)=1;
            Aw(i)=1;
            Su(i)= 0;
            Sp(i)=0;
            Ap(i)=Ae(i)+Aw(i)-Sp(i);
            
            E(i,i-1)=-Aw(i);
            E(i,i)=Ap(i);
            E(i,i+1)=-Ae(i);
        else
            Ae(i)=0;
            Aw(i)=1;
            Su(i)= 2*Tp2;
            Sp(i)=-2;
            Ap(i)=Ae(i)+Aw(i)-Sp(i);
            
            E(i,i-1)=-Aw(i);
            E(i,i)=Ap(i);
        end
    end
end
% fprintf('Informa��es da Matriz e vetor')
% E
% Su

% Subrotina para o c�lculo dos coeficientes:
%Checkpoint
[residue_TDMA,it_final_TDMA,T_TDMA,tempo_TDMA]=TDMA(Ae,Aw,Su,Ap,nv,T,erro,kmax);
[residue_jacobi,it_final_jacobi,T_jacobi,tempo_jacobi]=gauss(Ae,Aw,Su,Ap,nv,T,erro,kmax);
[residue_gauss,it_final_gauss,T_gauss,tempo_gauss]=gauss(Ae,Aw,Su,Ap,nv,T,erro,kmax);
[residue_SOR,it_final_SOR,T_SOR,tempo_SOR]=SOR(Ae,Aw,Su,Ap,nv,T,erro,kmax,w);

%% 3-plot de resultados

%Checkpoint
%solu��o anal�tica
pontosx=linspace(0,L,10000);
pontosy=-100/L*pontosx+150;

gcf=figure;
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);%Maximize window

plot(pontosx,pontosy,'--')
hold on
plot(x,T_TDMA,'ro')
hold on
plot(x,T_jacobi,'m-+')
hold on
plot(x,T_gauss,'g*')
hold on
plot(x,T_SOR,'yd')

title(['Lista 3'],'FontSize',20) %Legend options
ylabel(['Temperatura (�C)'])
xlabel('Comprimento (m)')
legend('Solu��o Anal�tica','TDMA','jacobi','gauss','SOR')

                      annotation('textbox',...
                        [0.50 0.7 0.2 0.2],...
                        'String',{'Tempo Calculado',...
                        ['TDMA: ' num2str(tempo_TDMA*100) ' e-2'],...
                        ['jacobi: ' num2str(tempo_jacobi*100) ' e-2'],...
                        ['gauss: ' num2str(tempo_gauss*100) ' e-2'],...
                        ['SOR: : ' num2str(tempo_SOR*100) ' e-2']},...
                        'FontSize',8,...
                        'FontName','Arial',...
                        'LineStyle','-',...
                        'EdgeColor',[1 1 0],...
                        'LineWidth',2,...
                        'BackgroundColor',[0.9  0.9 0.9],...
                        'Color',[0.84 0.16 0]);
                        
%% 4 - Functions
%TDMA
function [residue,it_final,T,tempo]=TDMA(Ae,Aw,Su,Ap,N,T,erro,kmax)
tic
for m=1:N
    A(m) = Ap(m);
    B(m) = -Ae(m);
    C(m) = -Aw(m);
    D(m) = Su(m); %A(i) � oriunda do programa principal (T)
end
% 2)(1� Passo) C�lculo do P(1) e do Q(1)
P(1) = -B(1)/A(1);
Q(1) = D(1)/A(1);
% 3) (2� Passo) C�lculo de todos os P(m) e Q(m)
for m=2:N
    P(m) = -B(m)/(A(m)+C(m)*P(m-1));
    Q(m) = (D(m)-C(m)*Q(m-1))/(A(m)+C(m)*P(m-1));
end
% !4) (3� Passo) Fazer a compara��o R(N)=Q(N)
T(N)=Q(N);
% !5) (4� Passo) Calcular R para todos os pontos de N-1 a 1
% for m=N:-1:2 % DO  variable = startValue, StopValue [, StepValue]
for m=N:-1:2 % DO  variable = startValue, StopValue [, StepValue]
    T(m-1) = P(m-1)*T(m) + Q(m-1);
end
residue=0;
it_final=0;
tempo=toc;
end

%jacobi
function [residue,it_final,T,tempo]=jacobi(Ae,Aw,Su,Ap,N,T,erro,kmax)
tic;
RMS=0;
%1) Estimativa inicial da vari�vel
for i=1:N
    M(i,1) = T(i); %A(i) � oriunda do programa principal (T)
end

%2) In�cio do processo iterativo
k=1; %Inicializa��o do contador de itera��es
while (k<kmax)
    %C�lculo da vari�vel com os valores da itera��o anterior
    for i=1:N
        if(i==1) %Primeiro Volume de Controle
            M(i,2)=(Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        elseif((i>1)&&(i<N)) %Volumes de Controle Internos
            M(i,2)=(Aw(i)*M(i-1,1)+Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        else %�ltimo Volume de Controle
            M(i,2)=(Aw(i)*M(i-1,1)+Su(i))/Ap(i);
        end
    end
    
    %3) C�lculo do Res�duo
    for i=1:N
        if((i>1)&&(i<N))
            %Res�duo Local
            Ri(i)=abs(Su(i)+Ae(i)*M(i+1,2)+Aw(i)*M(i-1,2)-Ap(i)*M(i,2) );
            % Res�duo da Itera��o
            RMS = RMS + Ri(i)^2.0;
        end
    end
    RMS = RMS^0.5;
    
    %4) Avan�o da itera��o
    for i=1:N
        M(i,1)=M(i,2);
    end
    
    %5) Verifica��o da converg�ncia
    if(RMS<=erro+1) %CONVERG�NCIA:
        it_final = k; %armazena a �ltima posi��o iterativa
        k=kmax; %for�a o fim da itera��es
        residue = RMS-1;
        
    else %SEM CONVERG�NCIA:
        k=k+1; %incremento de k
        it_final = k; %armazena a �ltima itera��o ->kmax
        residue = RMS-1;
    end
end %Finaliza��o do contador de itera��es

%6) Resultado que retorna para o programa principal
for i=1:N
    T(i)= M(i,2);
end
tempo=toc;
end

%Gauss-Seidel
function [residue,it_final,T,tempo]=gauss(Ae,Aw,Su,Ap,N,T,erro,kmax)
tic
RMS=0;
%1) Estimativa inicial da vari�vel
for i=1:N
    M(i,1) = T(i); %A(i) � oriunda do programa principal (T)
end

%2) In�cio do processo iterativo
k=1; %Inicializa��o do contador de itera��es
while (k<kmax)
    %C�lculo da vari�vel com os valores da itera��o anterior
    for i=1:N
        if(i==1) %Primeiro Volume de Controle
            M(i,2)=(Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        elseif((i>1)&&(i<N)) %Volumes de Controle Internos
            M(i,2)=(Aw(i)*M(i-1,2)+Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        else %�ltimo Volume de Controle
            M(i,2)=(Aw(i)*M(i-1,2)+Su(i))/Ap(i);
        end
    end
    
    %3) C�lculo do Res�duo
    for i=1:N
        if((i>1)&&(i<N))
            %Res�duo Local
            Ri(i)=abs(Su(i)+Ae(i)*M(i+1,2)+Aw(i)*M(i-1,2)-Ap(i)*M(i,2) );
            % Res�duo da Itera��o
            RMS = RMS + Ri(i)^2.0;
        end
    end
    RMS = RMS^0.5;
    
    %4) Avan�o da itera��o
    for i=1:N
        M(i,1)=M(i,2);
    end
    
    %5) Verifica��o da converg�ncia
    if(RMS<=erro+1) %CONVERG�NCIA:
        it_final = k; %armazena a �ltima posi��o iterativa
        k=kmax; %for�a o fim da itera��es
        residue = RMS-1;
        
    else %SEM CONVERG�NCIA:
        k=k+1; %incremento de k
        it_final = k; %armazena a �ltima itera��o ->kmax
        residue = RMS-1;
    end
end %Finaliza��o do contador de itera��es

%6) Resultado que retorna para o programa principal
for i=1:N
    T(i)= M(i,2);
end
tempo=toc;
end

%SOR
function [residue,it_final,T,tempo]=SOR(Ae,Aw,Su,Ap,N,T,erro,kmax,w)
tic
RMS=0;
%1) Estimativa inicial da vari�vel
for i=1:N
    M(i,1) = T(i); %A(i) � oriunda do programa principal (T)
end

%2) In�cio do processo iterativo
k=1; %Inicializa��o do contador de itera��es
while (k<kmax)
    %C�lculo da vari�vel com os valores da itera��o anterior
    for i=1:N
        if(i==1) %Primeiro Volume de Controle
            M(i,2)=(Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        elseif((i>1)&&(i<N)) %Volumes de Controle Internos
            M(i,2)=(Aw(i)*M(i-1,2)+Ae(i)*M(i+1,1)+Su(i))/Ap(i);
        else %�ltimo Volume de Controle
            M(i,2)=(Aw(i)*M(i-1,2)+Su(i))/Ap(i);
        end
    end
    
    %3) C�lculo do Res�duo
    for i=1:N
        if((i>1)&&(i<N))
            %Res�duo Local
            Ri(i)=abs(Su(i)+Ae(i)*M(i+1,2)+Aw(i)*M(i-1,2)-Ap(i)*M(i,2) );
            % Res�duo da Itera��o
            RMS = RMS + Ri(i)^2.0;
        end
    end
    RMS = RMS^0.5;
    
    %   !4) Avan�o da itera��o
    for i=1:N
        M(i,1)=w*M(i,2) + (1-w)*M(i,1);
    end
    
    %5) Verifica��o da converg�ncia
    if(RMS<=erro+1) %CONVERG�NCIA:
        it_final = k; %armazena a �ltima posi��o iterativa
        k=kmax; %for�a o fim da itera��es
        residue = RMS-1;
        
    else %SEM CONVERG�NCIA:
        k=k+1; %incremento de k
        it_final = k; %armazena a �ltima itera��o ->kmax
        residue = RMS-1;
    end
end %Finaliza��o do contador de itera��es

%6) Resultado que retorna para o programa principal
for i=1:N
    T(i)= M(i,2);
end
tempo=toc;
end
