classdef pn_learner
    % pn_learner keeps track of candidate training data + pn learning 
    %   value
    
    properties
        L;
        X;
        p_expert;
        n_expert;
        %class_f;
    end
    
    methods
        
        % inputs: L = labeled set with {'X' => matrix where row i = observations of i
        %                               'Y' => vector of {-1,1} representing labels of i}
        function [class_f] = initialize_pn_training(self, L)
            self.L = L;
            X = L.X;
            Y = L.Y;
            Y = (Y == 1); % changes so Y values of {0, 1}            
            
            class_f = NaiveBayes.fit(X,Y, 'Distribution', 'mn');
            %class_f = self.class_f;
        end
        
        function [predicted_features] = pn_testing(self, class_f, x_test)
            predicted_features = class_f.predict(x_test);
            
            if (predicted_features == 0) 
                predicted_features = -1;
            end
        end
        
        % X = rows represent one observation
        function [class_f] = pn_bootstraping(self, class_f, X)
            self.X = X;
            
            % run until some sort of convergence
            while true
                for i=1:length(X(:,1))
                    row_X = X(i,:);
                    row_pred = class_f.predict(row_X);

                    % somehow, from p-n experts, add ones that are 
                    % incorrect, using changed output results
                    self.L.X = [self.L.X; row_pred];
                    self.L.Y = [self.L.Y; -1 or 1 or w/e];
                end
            end
        end
        
        function [p_expert] = increment_pexpert(self) 
            self.p_expert = self.p_expert + 1;
            p_expert = self.p_expert;
        end
        function [n_expert] = increment_nexpert(self) 
            self.n_expert = self.n_expert + 1;
            n_expert = self.n_expert;
        end
        
        % input = labeled set L (length l)
        %       = unlabeled set X (length u) where (l << u)
        function [] = learn_that_shit(self)
            
        end
    end
    
end

