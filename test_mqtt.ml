open Sys
open Async.Std
open Mqtt_async

let run ~broker ~port () =  
   Pipe.set_size_budget pr 256 ;
   connect_to_broker ~broker ~port (fun t  ->
     process_publish_pkt ( fun topic payload msg_id -> 
                             printf "Topic: %s\n" topic;
                             printf "Payload: %s\n" payload;
                             printf "Msg_id is: %d\n" msg_id;
                             if topic = "PING" && payload.[0] <> 'A' then
                               ignore(publish ~qos:1 "PING" "A PONG to your PING!" t.writer)
                          );
     printf "Start user section\n";
     subscribe ["#"] t.writer ;
     ignore(publish "TOPIC_42" "THE ANSWER TO LIFE, THE UNIVERSE AND EVERYTHING!!!" t.writer);
     printf "subscribed\n"
   ); 
   Deferred.never () 

let () = 
  Command.async_basic
    ~summary: "Subscribing to all messages (#)"
    Command.Spec.(
      empty
      +> flag "-broker" (optional_with_default "test.mosquitto.org" string)
         ~doc: "broker address (defaults to \"test.mosquitto.org\")"
      +> flag "-port"   (optional_with_default 1883 int)
         ~doc: "port (defaults to 1883)"
     )
     ( fun broker port () -> run ~broker ~port () )
  |> Command.run

