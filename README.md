## nb_murder

norns [nb](https://llllllll.co/t/n-b-et-al-v0-1/60374) mod for a single or murder of crows over ii (i2c).

if you only have one crow, you should use [nb_crow](https://github.com/sixolet/nb_crow) instead. it has lots of awesome features (legato, portamento, adsr envelopes, etc) not available here.

if you own an (attempted?) murder of crows (2+), this mod will allow using the additional crows as additional nb voices, supporting up to 4 additional crows, and up to 8 (in cv/env mode) or 12 (in paraphonic mode) additional nb voices.

**supported nb targets:**

  - `cv/env pair`: two sets of cv/env pairs. crow output 1/3 are cv, 2/4 are triggers/envelopes/gates.
  - `paraphonic`: crow outputs 1-3 are cv, cycled between based on the `alloc mode`. crow output 4 is a trigger/envelope/gate shared across 3 voices.

**parameters:**

  - `ii address`: choose which crow this voice will go to. ii address can be set on the receiving crow using [these instructions](https://monome.org/docs/crow/reference/#setting-the-ii-address).
  - `trigger type`: pulse, gate, or attack/release envelope. only gate will be released on note off, the other two options use specific **time** params.
  - `alloc type`: choose how voices are cycled between when using paraphonic mode.

**installation:**

enter this command in your matron command line:
```
;install https://github.com/dwtong/nb_murder
```

if you have more than 2 crows (i.e. one leader and one follower), then update the "device count" in the nb_murder mod menu to the number of follower crows that you wish to use.
