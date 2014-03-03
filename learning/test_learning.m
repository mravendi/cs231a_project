
clear all;
close all;


% test naive-bayes

X = [ 0 0 1 1 0 ;
1 0 1 0 0 ;
1 1 0 1 0 ;
1 1 0 0 0 ;
0 1 0 1 0 ;
0 0 1 0 0 ;
1 0 1 1 1 ;
1 1 0 1 1 ;
1 1 1 0 1 ;
1 1 1 0 1 ;
1 1 1 1 1 ;
1 0 1 0 1 ;
1 0 0 0 1 ];

Y = X(:,5);
X = X(:,1:4);

%fits = NaiveBayes.fit(X,Y, 'Distribution', 'mn');

learner = pn_learner();
L = {};
L.X = X;
L.Y = Y;
class_f = learner.initialize_pn_training(L);

x_test = [ 0 0 1 1 ];
output = learner.pn_testing(class_f, x_test);
