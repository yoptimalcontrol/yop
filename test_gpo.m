% syms x1 x2 x3 x4


yop.options.set_symbolics('casadi')
% yop.options.set_symbolics('symbolic_math')
%%
v1 = yop.variable('v1');
v2 = yop.variable('v2');
v3 = yop.variable('v3');
v4 = yop.variable('v4');

%%
n1 = v1 + v2;
n2 = v1 + v3;
n3 = n1 + n2; % 2*v1 + v2 + v3
n4 = n3 + n2; % 3*v1 + v2 + 2*v3
n5 = n4 + v4; % 3*v1 + v2 + 2*v3 + v4

%%
% v1.value = 1;
% v2.value = 1;
% v3.value = 1;
% v4.value = 1;

%%
n5.evaluate()
