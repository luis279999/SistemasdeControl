clc;
clear;
close all;
Da = xlsread('Curvas_Medidas_Motor_20266.xls');

t = Da(:,1);      % tiempo
y = Da(:,2);      % velocidad wr
i = Da(:,3);      % corriente
v = Da(:,4);      % tension
tl = Da(:,5);     % torque

%figure(1);

%subplot(4,1,1)
%plot(t,v,'LineWidth',1.5)
%grid on
%title('Tensión')
%ylabel('V [V]')

%subplot(4,1,2)
%plot(t,i,'LineWidth',1.5)
%grid on
%title('Corriente')
%ylabel('I [A]')

%subplot(4,1,3)
%plot(t,y,'LineWidth',1.5)
%grid on
%title('Velocidad')
%ylabel('\omega [rad/s]')

%subplot(4,1,4)
%plot(t,tl,'LineWidth',1.5)
%grid on
%title('Torque')
%ylabel('T [N·m]')
%xlabel('Tiempo [s]')

Ra= 1.0522002944051294; 
Laa= 1.1050455179761307; 
Ki= 10.52420787895219;
Jm= 2.004699007568337; 
Bm= 0.5273735299363512; 
Km= 0.09739802918189874;

A= [-Ra/Laa -Km/Laa 0; Ki/Jm -Bm/Jm 0; 0 1 0];
B= [1/Laa 0;0  -1/Jm;0 0];
C= [0 0 1];
D= [0 0];

sys= ss(A,B,C,D)
%verificamos la controlabilidad de nuestro sistema
M = ctrb(A,B)
rank(M)
%el sistema es controlable por lo que procedemos a
%definir el controlador LQR

Q = diag([1 1 50 250]);

R = 50;
% Discretizacion
Ts = 0.01;

sysd = c2d(sys,Ts,'zoh');

Ad = sysd.A;
Bd = sysd.B;

%ampliacion de las matrices
Aampd = [Ad zeros(3,1);
        -C*Ad 1];

Bampd = [Bd(:,1);
        -C*Bd(:,1)];

Camp=[C 0];

%Verificacion de la ampliacion
Ma = ctrb(Aampd,Bampd);
rank(Ma);

%Calculo del LQR discreto
[K,S,P] = dlqr(Aampd,Bampd,Q,R);

Acl = Aampd-Bampd*K;
eig(Acl)

%tiempo de simulacion
Tsim=40;

t = 0:Ts:Tsim;

%creacion de vectore para Pi/2
%y otro para el torque
ref = pi/2*ones(size(t));
Tl = zeros(size(t));

%Condiciones iniciales del sistema
xop = [0 0 0]';

ia(1)=0;
theta(1)=0;
wr(1)=0;

stateVec = [ia(1) wr(1) theta(1)]';

x = stateVec;

zeta(1)=0;
integ=0;

%como no puede medirse la corriente de plantea un observador

Cobs = [0 1 0;
        0 0 1];

%verificamos si es observable

Obs = obsv(A,Cobs);
rank(Obs);

%si es observable procedemos

Ao = Ad';
Bo = Cobs';

Qo = diag([1 250 1]);
Ro = diag([10 10]);

Ko = dlqr(Ao,Bo,Qo,Ro);

L = Ko';

disp('Polos observador')
eig(Ad-L*Cobs)

xObs = [0 0 0]';

iaO(1)=0;
wrO(1)=0;
thetaO(1)=0;

for i=1:length(t)-1

    %Torque es de 20
    %Empieza desde los 18.68
    %Termina a los 26.67s

    if t(i)>=18.68 && t(i)<=26.67
        Tl(i)=20;
    else
        Tl(i)=0;
    end

    %Grafica del +pi/2 a -pi/2

    if mod(floor(t(i)),30)<15
        ref(i)=pi/2;
    else
        ref(i)=-pi/2;
    end

    %calculo del error

    zP = ref(i)-C*stateVec;

    %integracion del error

    zeta(i+1)=zeta(i)+ref(i)-theta(i);

    %señal control usando estados observados

    u(i)=-K(1:3)*xObs-K(4)*zeta(i);



    % Sistema discreto real

    x = Ad*x + Bd(:,1)*u(i) + Bd(:,2)*Tl(i);

    ia(i+1)=x(1);
    wr(i+1)=x(2);
    theta(i+1)=x(3);

    ymed = [wr(i+1);
            theta(i+1)];

    yh = Cobs*xObs;

    %Observador discreto

    xObs = Ad*xObs + Bd(:,1)*u(i) + L*(ymed-yh);

    % Estados observados

    iaO(i+1)=xObs(1);
    wrO(i+1)=xObs(2);
    thetaO(i+1)=xObs(3);

    stateVec = x;

    integ = zeta(i+1);

end

u(end)=u(end-1);



% Seguimiento de referencia

figure

plot(t,ref,'k--','LineWidth',1.5)

hold on

plot(t,theta,'LineWidth',1.5)

grid on

xlabel('Tiempo [s]')
ylabel('\theta [rad]')

legend('Referencia','Posición')

title('Seguimiento de referencia')


% grafico de la corriente

figure

plot(t,ia,'b','LineWidth',1.5)
hold on
plot(t,iaO,'r--','LineWidth',1.5)

grid on

xlabel('Tiempo [s]')
ylabel('Corriente [A]')

title('Corriente real vs estimada')

legend('Real','Estimada')

