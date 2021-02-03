#include "../partial/Lambda.ligo"

type storage is record [
    counter : nat;
    threshold : nat;
    pubKeys : list(key);
]

type return is list(operation) * storage

type changeParams is michelson_pair(
    nat, "threshold",
    list(key), "keys"
)

type actionParam is
| Action of func
| KeyChange of changeParams

type mainParam is michelson_pair(
    nat, "counter",
    actionParam, "action"
)

type inputParam is michelson_pair(
    mainParam, "action",
    list(option(signature)), "sigs"
)

type actions is
| Default of unit
| MainAction of inputParam

function checkSignatures(const pubKeys : list(key); const input : inputParam) is
block {
    var sigCounter := 0n;
    var signatures := input.1;

    // Loop check all signatures
    for key in list pubKeys block {
        case List.head_opt(signatures) of
        | None -> skip
        | Some(s) -> block {
            case s of
            | None -> skip
            | Some(h) -> block {
                // Check signature
                if Crypto.check(key, h, Bytes.pack(input.0)) = True then
                    sigCounter := sigCounter + 1n;
                else
                    skip;
            }
            end;
        }
        end;
        // Remove head element
        case List.tail_opt(signatures) of
        | None -> signatures := (nil : list(option(signature)))
        | Some(tail) -> signatures := tail
        end;
    }
} with sigCounter

function processAction(const input : inputParam; const s : storage) : return is
block {
    if input.0.0 =/= s.counter then
        failwith("Counter don't match")
    else
        skip;

    if checkSignatures(s.pubKeys, input) < s.threshold then
        failwith("Quorum not presented")
    else
        skip;

    s.counter := s.counter + 1n;

    var response := (nil : list(operation));

    // Process action
    case input.0.1 of
    | Action(n) -> response := n(unit)
    | KeyChange(n) -> skip // TODO change keys and threshold
    end;
} with (response, s)

function main(const action : actions; const s : storage) : return is
case action of
| Default -> ((nil : list(operation)), s)
| MainAction(v) -> processAction(v, s)
end
