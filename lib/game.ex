defmodule Game do
    use GenServer
    defstruct [player1: %Player{}, player2: %Player{}, array: [1,2,3,4,5,6,7,8,9], entry: true]
    @winning [
                ["1","2","3"], 
                ["4","5","6"], 
                ["1","4","7"], 
                ["2","5","8"], 
                ["3","6","9"], 
                ["1","5","9"], 
                ["3","5","7"],
                ["7","8","9"]
            ]

            #Client
            def start_link do
                GenServer.start_link(__MODULE__, %Game{})
            end

            def value(pid, val \\ 0) do
                GenServer.call(pid, {:value, val})
            end

            def create(pid, num) do
                IO.puts "Enter a name player#{num}"
                name=IO.gets("") |> String.trim
                GenServer.cast(pid, {:create, name, num})
            end

            def display_board(pid, val \\ 0) do
                GenServer.call(pid, {:display, val})
            end

            def play(pid, player) do
                game=value(pid)
                if player==1 do
                    IO.puts "Pick a position #{game.player1.name}"
                    place=IO.gets("") |> String.trim |> String.to_integer
                    GenServer.cast(pid, {:play, place, player, pid})
                else
                    IO.puts "Pick a position #{game.player2.name}"
                    place=IO.gets("") |> String.trim |> String.to_integer
                    GenServer.cast(pid, {:play, place, player, pid})
                end
            end

            def won(player) do
             IO.puts "#{player.name} won"
             Process.exit(self(), :success)
            end

            def tie do
                IO.puts "It is a tie"
                Process.exit(self(), :tie)
            end

            def check(pid, number) do
                GenServer.call(pid, {:check, number})
            end

            def start_play(i, _pid) when i==10, do: tie()

            def start_play(i, pid) do
                if rem(i,2)==1 do
                    play(pid, 1)
                    if value(pid).entry do
                        display_board(pid)
                        check(pid, 1)
                        start_play(i+1, pid)
                    else
                        display_board(pid)
                        start_play(i, pid)
                    end
                else
                    play(pid, 2)
                    if value(pid).entry do
                        display_board(pid)
                        check(pid, 2)
                        start_play(i+1, pid)
                    else
                        display_board(pid)
                        start_play(i, pid)
                    end
                end
            end
            
            def start(pid) do
                for x <- 1..2 do
                    create(pid, x)
                end
                IO.puts "Let the game begin"
                display_board(pid)
                start_play(1, pid)
            end

            def show(state) do
                IO.puts "-----------"
                state.array
                |>Enum.with_index
                |>Enum.each(fn({x, i})->
                    if rem(i,3)< 2 do
                        IO.write " #{x} |"
                    else
                        IO.puts x
                        IO.puts "-----------"
                    end
                end)
            end

            #Server
            def init(state) do
                {:ok, state}
            end

            def handle_call({call, value}, _from, state) do
                cond do
                    call == :display ->
                        {:reply, show(state), state}
                    call == :value ->
                        {:reply, state, state}
                    true ->
                        if value==1 do
                            t=for x <- @winning do
                                if Enum.all?(x, fn(y) -> Enum.member?(state.player1.array, String.to_integer(y)) end) do
                                    true
                                end
                            end

                            if Enum.member?(t, true) do
                                {:reply, won(state.player1), state}
                            else
                                {:reply, state, state}
                            end
                        else
                            t=for x <- @winning do
                                if Enum.all?(x, fn(y) -> Enum.member?(state.player2.array, String.to_integer(y)) end) do
                                    true
                                end
                            end

                            if Enum.member?(t, true) do
                                {:reply, won(state.player2), state}
                            else
                                {:reply, state, state}
                            end
                        end
                    end
                end

            def handle_cast({:create, value, num}, state) do
                if num== 1 do
                    newstate=%{state.player1| name: value, key: "X"}
                    state=%{state| player1: newstate}
                    {:noreply, state}
                else
                    newstate=%{state.player2| name: value, key: "O"}
                    state=%{state| player2: newstate}
                    {:noreply, state}
                end
            end

            def handle_cast({:play, position, player, _pid}, state) do
                if is_integer(Enum.at(state.array, position-1))&&position <= 9 do
                    if player==1 do
                        playerstate=%{state.player1| array: [position| state.player1.array]}
                        state=%{state| array: List.replace_at(state.array, position-1, state.player1.key), player1: playerstate, entry: true}
                        {:noreply, state}
                    else
                        playerstate=%{state.player2| array: [position| state.player2.array]}
                        state=%{state| array: List.replace_at(state.array, position-1, state.player2.key), player2: playerstate, entry: true}
                        {:noreply, state}
                    end
                else 
                    state=%{state| entry: false}
                    IO.puts "Invalid entry, try again"
                    {:noreply, state}
                end
            end
        end