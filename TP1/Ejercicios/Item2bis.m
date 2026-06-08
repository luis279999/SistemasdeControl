clc;close all;

Da = xlsread('Curvas_Medidas_RLC_2026.xls');%Da=datos
t = Da(:,1);   % tiempo
y = Da(:,3);   % señal
%figure(1)
%plot(Da(:,1),Da(:,2)); %grafico de corriente
%title('i_a variable de estado x_1')
%xlabel('Tiempo [Seg.]');
%ylabel('Corriente [Amp.]');

%figure(2)
%plot(Da(:,1),Da(:,3)); %grafico de voltaje de capacitor
%title('V_c var. de est. x_2')
%grid on;
%xlabel('Tiempo [Seg.]');
%ylabel('Voltaje [Volt]');

%Recortar hasta 0.5 segundos
idx = t <= 0.5;

t_rec = t(idx);
y_rec = y(idx);
% Normalizar a escalón unitario
y_min = min(y_rec);
y_max = max(y_rec);

y_norm = (y_rec - y_min) / (y_max - y_min);
% Graficar
figure
plot(t_rec, y_norm, 'LineWidth', 1.5)
hold on
grid on
xlabel('Tiempo [seg]')
ylabel('Tensión [V]')
title('Hasta 0.5 segundos')

%se toman 3 puntos equisdistantes y se obtienen los valores de
%x1,x2,x3,y1,y2,y3
SetAmplitude=1;
k=12;
i=1250;
n=225;
y_1=Da(i,3);
x_1=Da(i,1);
y_2=Da(i+n,3);
x_2=Da(i+n,1);
y_3=Da(i+n*2,3);
x_3=Da(i+n*2,1);
%Normalizo a un valor unitario
k1=y_1/k-1;
k2=y_2/k-1;
k3=y_3/k-1;
%obtengo valores de beta,alfa1,alfa2,y b
be=4*k1^3*k3-3*k1^2*k2^2-4*k2^3+k3^2+6*k1*k2*k3;
alfa1=(k1*k2+k3-sqrt(be))/(2*(k1^2+k2));
alfa2=(k1*k2+k3+sqrt(be))/(2*(k1^2+k2));
beta=(k1+alfa2)/(alfa1-alfa2);
%calculo las constantes de tiempo T1,T2,T3
T1_ang=-0.0225/log(alfa1);
T2_ang=-0.0225/log(alfa2);
T3_ang=beta*(T1_ang-T2_ang)+T1_ang;
s=tf('s');
G=(1)/((T1_ang*s +1)*(T2_ang*s +1))
[numG,denG]=tfdata(G,'v');
%grafico obtenido
t_sim = linspace(0, max(t_rec), 1000);
[y_modelo2, t_modelo2] = step(G, t_sim);

% Si querés incluir delay (si lo detectaste antes)
L = 0.1; % ajustá si corresponde
t_modelo2 = t_modelo2 + L;

% Graficar encima
plot(t_modelo2, y_modelo2, 'g--', 'LineWidth', 1.5)

legend('Datos reales','Modelo 2do orden obtenido')
hold off
% Calculo de R C y L para el modelo obtenido
% doy un valor aleatorio a C para poder obtener los valores de R y L para
% el modelado del sistema
R=220
C=denG(1,2)/(R)
L=denG(1,1)/C

% Datos reales
Da = xlsread('Curvas_Medidas_RLC_2026.xls');
t_data = Da(:,1);
y_data = Da(:,3);

figure(4)
plot(t_data, y_data, 'b', 'LineWidth', 1.5)
hold on
grid on

% Señal de entrada
h = 0.001;
t_sim = 0:h:2;
u = zeros(size(t_sim));

variable = 0;

for i = 1:length(t_sim)
    
    if variable < (0.5/h)
        val = 12;
    else
        val = -12;
    end
    
    variable = variable + 1;
    
    if variable >= (1/h)
        variable = 0;
    end
    
    if t_sim(i) < 0.1
        u(i) = 0;
    else
        u(i) = val;
    end
end

% Sistema
Mat_A=[-R/L -1/L;1/C 0];
Mat_B=[1/L;0];
Mat_C=[0 1];

sys1=ss(Mat_A,Mat_B,Mat_C,[]);

% Simulación (IMPORTANTE)
y_sim = lsim(sys1,u,t_sim);

% Graficar encima
plot(t_sim, y_sim, 'r--', 'LineWidth', 1.5)

xlabel('Tiempo [Seg.]');
ylabel('Voltaje [Volt]');
title('Comparación: Datos vs Modelo');
legend('Datos reales','Modelo')
hold off;

%grafico de la corriente
% Datos reales
Da = xlsread('Curvas_Medidas_RLC_2026.xls');
t_data = Da(:,1);
y_data = Da(:,2);

figure(5)
plot(t_data, y_data, 'b', 'LineWidth', 1.5)
hold on
grid on

% Sistema
C=[1 0];

sys2=ss(Mat_A,Mat_B,C,[]);

% Simulación (IMPORTANTE)
y_sim = lsim(sys2,u,t_sim);

% Graficar encima
plot(t_sim, y_sim, 'r--', 'LineWidth', 1.5)

xlabel('Tiempo [Seg.]');
ylabel('Voltaje [Volt]');
title('Comparación: Datos vs Modelo');
legend('Datos reales','Modelo')
hold off;



