clc; close all;

% Lectura de los datos otorgados
Da = xlsread('Curvas_Medidas_Motor_20266.xls');
t_data = Da(:,1);
y_data = Da(:,2);
i_data = Da(:,3);
v_data = Da(:,4);
tl_data = Da(:,5);

% Parámetros del motor
Ra  = 1.0522002944051294;
Laa = 1.1050455179761307;
Ki  = 10.52420787895219;
Jm  = 2.004699007568337;
Bm  = 0.5273735299363512;
Km  = 0.09739802918189874;
A = [ -Ra/Laa     -Km/Laa     0;
       Ki/Jm      -Bm/Jm      0;
       0           1          0];
B = [1/Laa    0;
      0     -1/Jm;
      0       0];
C = [0 0 1];
D = [0 0];
sys = ss(A,B,C,D);
%verificamos la controlabilidad de nuestro sistema
Mc = ctrb(A,B);
disp('Rango controlabilidad:')
rank(Mc)
% Discretización de nuestro sistema
Ts = 0.01;      % 10 ms
sysd = c2d(sys,Ts,'zoh');
Ad = sysd.A;
Bd = sysd.B;
Cd = sysd.C;
Dd = sysd.D;
%ampliacion de las matrices
Aamp = [Ad zeros(3,1);
       -Cd 1];
Bamp = [Bd(:,1);
         0];
%Calculo del LQR
Q = diag([0.1 0.1 0.1 1]);
R = 1000;
[K,S,P] = dlqr(Aamp,Bamp,Q,R);
disp('Ganancias LQR')
K
disp('Polos lazo cerrado')
eig(Aamp-Bamp*K)
Tsim = 40;
t = 0:Ts:Tsim;
N = length(t);
%Condiciones iniciales del sistema
ia    = zeros(1,N);
wr    = zeros(1,N);
theta = zeros(1,N);

u   = zeros(1,N);
ref = zeros(1,N);
Tl  = zeros(1,N);
x = [0 0 0]';
zeta = 0;
for k = 1:N
    %Torque es de 20
    %Empieza desde los 18.68
    %Termina a los 26.67s
    if t(k)>=18.68 && t(k)<=26.67
        Tl(k)=20;
    else
        Tl(k)=0; % En caso que no este entre los 18.68 y 40 s
    end
    %Grafica del +pi/2 a -pi/2
    if mod(floor(t(k)),30)<15
        ref(k)=pi/2;
    else
        ref(k)=-pi/2;
    end
    %calculo del error
    e = ref(k)-x(3);
    zeta = zeta + e;
    u(k)= -K(1:3)*x - K(4)*zeta;
    ia(k)=x(1);
    wr(k)=x(2);
    theta(k)=x(3);
    x = Ad*x + Bd(:,1)*u(k) + Bd(:,2)*Tl(k);

end
figure

subplot(4,1,1)

plot(t,ref,'r--','LineWidth',1.5)
hold on
plot(t,theta,'b','LineWidth',1.5)

grid on
xlim([0 40])

title('Referencia y posicion angular')
xlabel('Tiempo [s]')
ylabel('\theta [rad]')

legend('Referencia','Salida')

subplot(4,1,2)

plot(t,u,'LineWidth',1.5)

grid on
xlim([0 40])

title('Señal de control')
xlabel('Tiempo [s]')
ylabel('u(t) [V]')

subplot(4,1,3)

plot(t,Tl,'LineWidth',1.5)

grid on
xlim([0 40])

title('Torque de carga')
xlabel('Tiempo [s]')
ylabel('T_L [N.m]')

subplot(4,1,4)

plot(t,ia,'LineWidth',1.5)

grid on
xlim([0 40])

title('Corriente de armadura')
xlabel('Tiempo [s]')
ylabel('i_a [A]')

% Plano de fases

%figure

%plot(theta,wr,'LineWidth',1.5)

%grid on

%xlabel('\theta [rad]')
%ylabel('\omega_r [rad/s]')

%title('Plano de fases')

% Error de posición

%figure

%plot(t,ref-theta,'LineWidth',1.5)

%grid on

%xlabel('Tiempo [s]')
%ylabel('e_\theta [rad]')

%title('Error de posición')