# Orchestration Brick
This brick allows you to declaratively state the order of execution of processes in that particular project. While there is rudimentary orchestration support in GoodData product some of useful usecases are not supported. This is designed to solve those situations. The problem is mainly the fact, that platform allows schedule to depende on only one other schedule.

## Key Features:
- Allows you to declaratively build the DAG of execution
- Let's you specify multiple dependencies
- This brick does not work with unscheduled processes

## Limitations
- Currently works inside project boundaries
- The orchestrator itself is a running process so it has the same limitations as any other. Notably can run only ~5 hours.

## Todo
- global retry specification
- handle case with cycle

### Preconditions
This brick currently works with names of schedules. There are couple of preconditions you have to fulfil

- Schedules have to be named uniquely
- Schedules have to have reschedule parameter unset or set to zero so the schedules are not automatically rerun on failure

### Definition
Definition is pretty simple. You specify the dependencies as list of rules. The rule is itself a list that has up to 3 parts. First part is the name of the schedule the rule is defined for. Second part is the list of schedule names that has to be finished succesfully before this schedule can be itself executed. Third parameter is optional dictionary/hash of parameters.

Let's have a look at real example. Let's say you have several schedules in your project. You would like to execute them like this.

![Schedule DAG](https://www.dropbox.com/s/pwoog8bh8d803xf/dag.png?dl=0&raw=1)

This can be translated in the following rules

    [
      ["a", []],
      ["b", ["a"]],
      ["c", ["b"]],
      ["d", ["b"]],
      ["e", ["c", "d"]]
    ]

Take note that the order of the rules does not matter. This definition is expected to be passed as "definition" key into the params

    "params": {
      "definition": [
        ["a", []],
        ["b", ["a"]],
        ["c", ["b"]],
        ["d", ["b"]],
        ["e", ["c", "d"]]
      ]
    }

Here is an example output when running this brick.

    Running ["a", []]
    Process finished "a" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f5159e4b04dc2ca9dbd78/executions/559f52aee4b0e23e7b74d11c
    Running ["b", ["a"]]
    Process finished "b" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ae4b0e23e7b74cfc1/executions/559f52b9e4b04dc2ca9dbd83
    Running ["c", ["b"]]
    Running ["d", ["b"]]
    Process finished "c" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ae4b04dc2ca9dbd79/executions/559f52c3e4b0e23e7b74d11d
    Process finished "d" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515be4b04dc2ca9dbd7a/executions/559f52c4e4b0e23e7b74d11e
    Running ["e", ["c", "d"]]
    Process finished "e" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ce4b0e23e7b74cfc2/executions/559f52d9e4b04dc2ca9dbd84
    Definition succesfully executed

### Dealing with failure
Processes occasionally fail. You can specify number of attempts it should be retried before failure. If we use the previous example again it might look like this.


    "params": {
      "definition": [
        ["a", [], { "retries" : 3}],
        ["b", ["a"], { "retries" : 3}],
        ["c", ["b"], { "retries" : 3}],
        ["d", ["b"], { "retries" : 3}],
        ["e", ["c", "d"], { "retries" : 3}]
      ]
    }

Example output when times are rough (each schedule had 50 percent chance of failure) might look like this

    Running ["a", [], {"retries"=>3}]
    Process "a" failed. Restarting process. Attempt 2.
    Process "a" failed. Restarting process. Attempt 3.
    Process finished "a" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f5159e4b04dc2ca9dbd78/executions/559f5716e4b0e23e7b74d257
    Running ["b", ["a"], {"retries"=>3}]
    Process "b" failed. Restarting process. Attempt 2.
    Process finished "b" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ae4b0e23e7b74cfc1/executions/559f5735e4b04dc2ca9dbdd6
    Running ["c", ["b"], {"retries"=>3}]
    Running ["d", ["b"], {"retries"=>3}]
    Process finished "c" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ae4b04dc2ca9dbd79/executions/559f5740e4b0e23e7b74d26d
    Process "d" failed. Restarting process. Attempt 2.
    Process finished "d" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515be4b04dc2ca9dbd7a/executions/559f5769e4b04dc2ca9dbdd7
    Running ["e", ["c", "d"], {"retries"=>3}]
    Process finished "e" /gdc/projects/wl3oo0dry05rkebwgc9awtlxo8fhjauw/schedules/559f515ce4b0e23e7b74cfc2/executions/559f57bbe4b0e23e7b74d287
    Definition succesfully executed

### Visualizing the graph

Picture is worth a thousand words. It is very easy to turn the definition in something more visual. This simple graphs will produce this result

    require 'graphviz'

    definition = [
      ["a", []],
      ["b", ["a"]],
      ["c", ["b"]],
      ["d", ["b"]],
      ["e", ["c", "d"]]
    ]

    g = GraphViz.new( :G, :type => :digraph , :rankdir => 'BT')
    definition.each { |rule| g.add_nodes( rule.first ) }
    definition.each { |rule| rule[1].each { |dep| g.add_edges(rule.first, dep) } }
    g.output( :png => "run_dag.png" )

![Schedule DAG](https://www.dropbox.com/s/fj5burfpo0vho2w/run_dag.png?dl=0&raw=1)

Just note you have to install the correct dependenecies. You have to install graphviz [http://www.graphviz.org/](http://www.graphviz.org/) and ruby library [Ruby Graphviz](https://github.com/glejeune/Ruby-Graphviz)