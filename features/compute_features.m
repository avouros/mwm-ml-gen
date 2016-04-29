function [ featval_all ] = compute_features(obj,features,variables,fn)
%% COMPUTE_FEATURES computes the features found in features_list.m.
% The features are computed by calling the appropriate functions required
% per feature and passing the appropriate arguments.
%%
    
    % progress %
    if length(obj)<1000
        div = 100;
    else 
        div = 1000;
    end

    featval_all = zeros(length(obj), length(features));
    id = hash_value(length(obj));
    id = hash_combine(id, length(features));
    fn_all = fullfile(fn, ['features_'  num2str(id(1)) '.mat']);
    if exist(fn_all, 'file') % see if we have it cached
        load(fn_all);                    
        featval = featval_all;
    else    
        for idx = 1:length(features)
            featval = zeros(length(obj),1);
            id = hash_value(length(obj));
            id = hash_combine(id, features{idx}{1,1});
            fn_ = fullfile(fn, ['features_'  strcat(features{1,idx}{1},'_',num2str(id(1))) '.mat']);
            if exist(fn_, 'file') % see if we have it cached
                load(fn_);                    
                featval(:, idx) = tmp;
            else % no cached - compute it
                % show progress per feature
                fprintf('\nComputing ''%s'' feature values for %d trajectories/segments...', features{idx}{1,2}, length(obj));
                q = floor(length(obj) / div);
                fprintf('0.0% '); 
                
                for i = 1:length(obj)
                    switch length(features{idx})
                        case 3 % no COMMON_PROPERTIES and Extra Values 
                            call_func = str2func(features{idx}{1,3});
                            v_length = 0;
                            values = zeros(1,v_length);  
                            featval(i, idx) = call_func(obj(i));

                        case 4 % COMMON_PROPERTIES and no Extra Values
                            call_func = str2func(features{idx}{1,3});
                            v_length = length(features{idx}{1,4});
                            values = zeros(1,v_length);
                            count = 1;
                            for v = 1:length(features{idx}{1,4}) % assign values to the variables
                                for j = 1:length(variables)
                                    if strcmp(variables{j},features{idx}{1,4}{v});
                                        values(v) = variables{j+1}{1};
                                        count = count+1;
                                        break;
                                    end
                                end    
                            end 
                            featval(i, idx) = call_func(obj(i),values);

                        case 5 % COMMON_PROPERTIES and Extra Values
                            call_func = str2func(features{idx}{1,3});
                            v_length = length(features{idx}{1,4}) + length(features{idx}{1,5});
                            values = zeros(1,v_length);
                            count = 1;
                            for v = 1:length(features{idx}{1,4}) % assign values to the variables
                                for j = 1:length(variables)
                                    if strcmp(variables{j},features{idx}{1,4}{v});
                                        values(v) = variables{j+1}{1};
                                        count = count+1;
                                        break;
                                    end
                                end    
                            end
                            % extra arguments
                            for v = 1:length(features{idx}{1,5});
                                values(count) = features{idx}{1,5}{v};
                                count = count+1;
                            end
                            featval(i, idx) = call_func(obj(i),values);
                            
                        otherwise % error
                            error('Error computing feature %d',idx);
                    end

                    % show the progress
                    if mod(i, q) == 0
                        val = 100.*i/length(obj);
                        if val < 10.
                            fprintf('\b\b\b\b\b%02.1f%% ', val);
                        else
                            fprintf('\b\b\b\b\b%04.1f%%', val);
                        end
                    end 
                end
                fprintf('\b\b\b\b\bDone.\n');
                % save it
                tmp = featval(:, idx);
                save(fn_, 'tmp');
            end
            % store it with the previous computed features
            featval_all(:, idx) = tmp;
        end
    end
    % save all the computed features
    save(fn_all, 'featval_all');

end

