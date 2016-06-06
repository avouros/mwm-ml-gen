function [ inst, error ] = fix_data( inst )
%FIX_DATA fixes the numbering of the trials and days and excludes animal
% participated in less/more trials than the ones specified.
% e.g. 4trials/day, for animal id x we need to have:
% day 1: 1,2,3,4. day 2: 5,6,7,8. day 3: 9,10,11,12.
% else id x is excluded

% The same animal id can exist in multiple sessions but in that case a new
% animal id will be generated for each session.

    % Total number of trials
    tps = inst.COMMON_SETTINGS{1,4}{1,1};
    if isstring(tps) || ischar(tps)
        number_of_trials = sum(str2num((tps)));
    elseif iscell(tps)
        number_of_trials = sum(cell2mat((tps)));
    else
        number_of_trials = sum(tps);
    end    
    
    % Days
    number_of_days = inst.COMMON_SETTINGS{1,8}{1,1};
    if isstring(number_of_days) || ischar(number_of_days)
        number_of_days = str2num((number_of_days));
    elseif iscell(number_of_days)
        number_of_days = cell2mat((number_of_days));
    end 

    ids = arrayfun( @(t) t.id, inst.TRAJECTORIES.items);
    sessions = arrayfun( @(t) t.session, inst.TRAJECTORIES.items);
    
    number_of_animals = unique(ids);
    excluded_ids = {};
    error = {};
    
    % check if animal id exists number_of_trials times in each session
    number_of_sessions = unique(sessions);
    for i = 1:length(number_of_sessions)
        % check if animal id exists number_of_trials times
        for a = 1:length(number_of_animals)
            current_id = find(ids == number_of_animals(a));
            if length(current_id) == number_of_trials
                continue
            % check if an animal id was used in multiple groups
            else
                multi_sessions = sessions(current_id);
                unique_multi_sessions = unique(multi_sessions);
                for w = 1:length(unique_multi_sessions)
                    ch = find(multi_sessions == unique_multi_sessions(w));
                    if length(ch) ==  number_of_trials
                        continue;
                    else
                        % save this id to exclude it later
                        excluded_ids{i,a} = number_of_animals(a);
                        excluded_ids = excluded_ids(~cellfun('isempty',excluded_ids));  
                        error{i} = excluded_ids;
                        break;
                    end    
                end  
            end
        end
        % exclude animal ids if necessary                      
        for k = 1:length(excluded_ids)
            if ~isempty(excluded_ids{1,k})
                ids = arrayfun( @(t) t.id, inst.TRAJECTORIES.items);
                sessions = arrayfun( @(t) t.session, inst.TRAJECTORIES.items);
                inst.TRAJECTORIES = trajectories(inst.TRAJECTORIES.items(ids ~= excluded_ids{1,k} & sessions == i));
            end
        end   
    end
    
    % Re-initialize
    ids = arrayfun( @(t) t.id, inst.TRAJECTORIES.items);
    groups = arrayfun( @(t) t.group, inst.TRAJECTORIES.items);
    trials = arrayfun( @(t) t.trial, inst.TRAJECTORIES.items);
    sessions = arrayfun( @(t) t.session, inst.TRAJECTORIES.items);
    
    number_of_animals = unique(ids);
    number_of_groups = unique(groups);
    
    % fix trials numbering
    ids_groups = zeros(2,length(ids));
    ids_groups(1,:) = ids;
    ids_groups(2,:) = groups;
    change_id = {};

    for i = 1:length(number_of_animals)
        temp = find(ids == number_of_animals(i));
        if length(temp) == number_of_trials
            for j = 1:number_of_trials
                trials(temp(j)) = j;
            end
        % if temp > number_of_trials then this animal id exist in multiple
        % animal groups or in multiple seessions.
        else
            for j = 1:length(number_of_groups)
                % find this animal id for only group j
                temp_2 = find(ids_groups(1,:) == ids(temp(1)) & ids_groups(2,:) == number_of_groups(j));
                if temp_2 == number_of_trials
                    for k = 1:length(temp_2)
                        trials(temp_2(k)) = k;
                    end
                % if the same group then this animal was used in multiple 
                % sessions thus enumerate trials from beginning per session
                % and provide another unique animal id per session.
                else
                    change_id = [change_id,{number_of_animals(i),temp_2}];
                    times_used = length(temp_2)/number_of_trials;
                    c = 1;
                    ti = 1;
                    n_idx = 1;
                    for t = 1:times_used
                        while ti <= length(temp_2) && c <= number_of_trials
                            trials(temp_2(ti)) = c;
                            ti = ti+1;
                            c = c+1;
                        end
                        c = 1;
                    end
                end    
            end
        end
    end
    
    % fix ids if necessary
    if ~isempty(change_id)
        for i = 1:2:length(change_id)
            animal = change_id{i};
            temp_2 = change_id{i+1};
            times_used = length(temp_2)/number_of_trials;
            %new_ids(1) would be the current id
            new_ids = animal;
            %new_ids(2+) would be the max(id)+1...
            for n_id = 1:times_used-1
                new_ids = [new_ids, max(number_of_animals)+n_id];
            end   
            start_ = 1;
            n_idx = 1;
            for k = 1:times_used
                end_ = k*number_of_trials;
                ids(temp_2(start_:end_)) = new_ids(n_idx);
                n_idx = n_idx + 1;
                start_ = end_+1; 
            end    
            number_of_animals = unique(ids);
        end    
    end    
    
    % fix days numbering
    number_of_sessions = unique(sessions);
    days = [];
    for i = 1:length(number_of_sessions)
        ses = find(sessions == number_of_sessions(i));
        days_ = length(ses)/number_of_days;
        temp_days = [];
        for j = 1:number_of_days
            for k = 1:days_
                temp_days(k) = j;
            end
            days = [days, temp_days];
        end  
    end
            
    % Assign fixed values
    for i = 1:length(inst.TRAJECTORIES.items)
        inst.TRAJECTORIES.items(i).trial = trials(i);
        inst.TRAJECTORIES.items(i).day = days(i);
        inst.TRAJECTORIES.items(i).id = ids(i);
    end    
    
    % If all animals were excluded notify the user
    if isempty(arrayfun( @(t) t.id, inst.TRAJECTORIES.items));
        error = {'all'};
    end    
end