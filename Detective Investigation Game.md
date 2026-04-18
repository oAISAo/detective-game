Detective Investigation Game
Design Documentation (Prototype Phase)

1. Vision
The goal of this project is to create a deep detective investigation game inspired by true crime stories and realistic criminal investigations.
The game focuses on:
deduction
evidence analysis
interrogation
timeline reconstruction
psychological pressure
investigation planning
The experience should feel like solving a real case, not following a scripted puzzle.
The player must:
gather evidence
analyze contradictions
build theories
interrogate suspects
reconstruct the timeline of events
The game intentionally avoids excessive guidance. The player must think like a real detective.

2. Core Design Philosophy
The game is designed around the following principles:
Player Deduction
The player performs the reasoning. The game does not automatically connect clues.
Realistic Investigation
Investigations unfold over time and require evidence before actions can be taken.
Imperfect Information
Evidence can be misleading, incomplete, or irrelevant.
Psychological Interrogation
Suspects react emotionally to questioning.
Narrative Depth
Characters have motives, relationships, and hidden secrets.
Investigation Over Action
The gameplay revolves around analyzing documents, interrogations, and evidence rather than physical exploration.

3. Game Format
The game uses an investigation management style interface rather than a fully 3D world.
This design decision was made to:
focus development resources on investigation systems
allow deep information analysis
maintain a realistic detective workstation feel
reduce development complexity
Similar investigative styles appear in games likeHer Story andReturn of the Obra Dinn.
The player essentially works inside a virtual investigation desk.

4. Core Gameplay Loop
The investigation follows a repeating loop:
Crime occurs
Player investigates the crime scene
Evidence is collected
Suspects emerge
Interrogations begin
Lab results arrive
Timeline reconstruction
Player forms theories
Evidence contradictions appear
Final accusation

5. Game Structure (Prototype Case)
The first prototype case will be intentionally small.
Case Structure
Suspects: 4
Locations: 5
Evidence items: ~25
Investigation days: 4
Timeline events: ~10

The purpose of the prototype is to test the investigation systems, not to build a large narrative.

6. Time System (Investigation Days)
The case unfolds over multiple in-game days.
Each day consists of:

Morning
New information arrives:
lab results
surveillance recordings
financial records
witness updates

Daytime
Player performs investigation actions.
Examples:
interrogate suspects
review evidence
request warrants
analyze documents
construct timeline
build theories

Night
The case progresses and certain story events may trigger.

7. Mandatory vs Optional Investigation Actions
Each investigation day contains two categories of tasks.
Mandatory Actions
Required before the day can progress.
Examples:
interrogating a key witness
reviewing the autopsy report
investigating the crime scene
Mandatory tasks ensure that the narrative progresses.
Optional Actions
Additional investigative activities.
Examples:
interviewing secondary witnesses
examining financial documents
reviewing surveillance footage
Optional actions may reveal:
additional evidence
deeper character motives
hidden relationships

8. Structured Investigation Timeline
Instead of a full simulation, the case follows a hidden narrative timeline.
Certain events occur automatically on specific days.
Other events are triggered by the player's actions.
Example:
DAY 1
Player interrogates witness Anna

DAY 2
Anna is found dead
Her testimony becomes critical evidence

This allows the story to progress while still feeling reactive.

9. Evidence System
Evidence forms the core of the investigation.
Evidence items can include:
forensic reports
photographs
witness statements
documents
phone records
financial transactions
surveillance images
Each evidence item contains metadata such as:
location found
time discovered
description
associated persons
Evidence is not automatically interpreted by the game.
Players must determine its meaning.

10. Evidence Categories
Evidence can fall into three categories.
Critical Evidence
Necessary to solve the case.
Supporting Evidence
Strengthens theories but is not required.
Noise Evidence
Irrelevant or misleading information.
Noise evidence creates realism and uncertainty.

11. Lab Processing System
Certain evidence must be analyzed by forensic laboratories.
Lab requests take time to process.
Examples:

This encourages investigation planning.
While waiting for results, players must pursue other leads.

12. Surveillance and Wiretap System
Players can request technical surveillance.
Examples include:
phone taps
home surveillance
financial monitoring
These installations require time to set up.
Once active, they may produce new evidence such as:
recorded conversations
suspicious meetings
hidden accomplices

13. Detective Board (Investigation Workspace)
The detective board acts as the player's reasoning workspace.
It functions as an investigation wall where the player organizes information.
The board contains several components.

Evidence Archive
The archive stores all collected evidence.
Players can:
tag items
highlight text
add notes
The archive does not automatically organize conclusions.

Case Board
Players manually place investigation cards representing:
suspects
locations
evidence
events
Cards can be connected using labeled relationship lines.
Example relationships:
financial connection
family
phone contact
seen together
This allows players to visualize the investigation. Same card can be placed on the board multiple times.

Timeline Reconstruction
Players construct the sequence of events leading to the crime.
Example:
18:45 victim arrives home
19:10 phone call with suspect
20:00 argument heard
21:05 estimated time of death

Evidence can be attached to timeline events.
Contradictions between events may reveal lies.

Theory Builder
Players can construct formal theories about the crime.
Example:
Suspect: Sarah Bennett
Motive: Financial dispute
Method: Kitchen knife
Time of death: 21:00

Evidence can be attached to support or contradict the theory.
The game evaluates evidence strength but never confirms the final solution.

14. Interrogation System
Interrogations are a central gameplay mechanic.
The system focuses on evidence confrontation rather than dialogue puzzles.
Each interrogation has three phases.

Phase 1 — Open Conversation
The suspect provides their initial story.
Statements are recorded as testimony.
Example:
"I left the house at 20:30."

Phase 2 — Evidence Confrontation
Players can present evidence contradicting statements.
Example:
Security footage shows the suspect leaving at 21:10.
The suspect must react.
Possible reactions include:
denial
anger
panic
silence
altered testimony

Phase 3 — Psychological Pressure
If contradictions accumulate, the suspect may:
reveal new information
expose another suspect
partially confess
Not all suspects will break.
Personality traits influence reactions.

15. Testimony Tracking
Every statement made during interrogation becomes a recorded item.
Statements can later be linked to evidence.
Example:
Statement:"I never entered the kitchen."
Evidence:Fingerprint on kitchen glass.
This creates a contradiction that the player can analyze.

16. Clue Design Principle (Mystery Writing Technique)
Professional mystery writers use the Clue Triangle principle.
Every major conclusion should be supported by three independent clues.
Example:
Conclusion: Suspect was present at the house.
Clue 1: Witness saw their car.Clue 2: Phone GPS location.Clue 3: Fingerprint found at scene.
This ensures mysteries are challenging but fair.

17. Evidence Interpretation
Evidence should not always have a single meaning.
Example:
Knife with fingerprints may mean:
murder weapon
kitchen utensil used earlier
planted evidence
Players must interpret evidence carefully.

18. Narrative Depth
The story should contain deeper layers beyond the murder itself.
Possible hidden story elements:
secret relationships
financial conflicts
past crimes
hidden accomplices
Players may solve the case without discovering every detail.
This encourages replay and discussion.

19. Player Experience Goals
The player experience should produce the following emotional cycle:
Confusion
Discovery
Pattern recognition
Theory formation
Breakthrough moment
The "breakthrough moment" is the core reward.

20. Community Potential
The game design intentionally encourages community discussion.
Players may:
share theories online
compare investigation boards
debate interpretations of evidence
A potential future feature could allow players to export their investigation boards.

21. Evidence Discovery System
Overview
The Evidence Discovery System governs how players investigate locations and uncover clues during a case.
The system is designed around detective reasoning rather than object searching. Instead of clicking randomly until evidence appears, players examine the environment, form investigative questions, and perform targeted examinations.
The goal is to create the feeling of thinking like a real detective, where observations lead to hypotheses and hypotheses lead to discoveries.
The system follows a simple reasoning model:

Observation → Question → Examination → Evidence

Players observe something unusual, decide what they want to investigate, and perform specific investigative actions to reveal evidence.

Location Investigation
Each case location contains a set of investigable objects.
Examples include:
furniture
personal items
electronic devices
physical surroundings
environmental details
When players arrive at a location, they are presented with these objects as points of interest rather than hidden clickable spots.
Example objects at a crime scene might include:
victim’s body
dining table
kitchen sink
broken picture frame
phone on the table
Players choose which objects to investigate.
Importantly, interacting with an object does not immediately reveal evidence.
Instead, it opens a set of possible investigative actions.

Investigative Actions
Every investigable object supports several possible actions.
Examples of actions include:
visual inspection
fingerprint analysis
residue testing
comparison with other objects
searching for hidden compartments
For example, examining two wine glasses at a table might offer the following actions:
inspect visually
check for fingerprints
analyze residue
compare with kitchen cabinet
Only certain actions will produce meaningful evidence.
This encourages players to think about what type of examination makes sense in the context of the situation.

Multi-Layer Investigation
Objects can contain multiple layers of information.
Initial inspection usually reveals basic observations, while deeper analysis can uncover more meaningful clues.
For example:
Broken Picture Frame
First inspection may reveal:
shattered glass
photograph of the victim and spouse
Further analysis may reveal:
glass fragments scattered outward
signs that the frame was knocked down during a struggle
This layered structure rewards careful investigation.

Evidence Generation
Evidence is generated when a correct investigative action is performed.
Examples include:
discovering fingerprints on a glass
identifying the murder weapon in a sink
recovering deleted messages from a phone
matching a shoe print with a suspect’s shoes
Some evidence appears immediately, while other evidence requires further processing.
For example:
fingerprints may require lab analysis
chemical traces may require forensic testing
digital evidence may require device searches
These delayed results contribute to the investigation timeline.

Evidence Pools
Each location contains a predefined evidence pool.
This pool represents all potential clues that could be discovered at that location.
Evidence pools include two categories:
Critical Evidence
Essential clues required to solve the case.
Examples:
murder weapon
suspect fingerprints
timeline evidence
Optional Evidence
Clues that deepen the narrative but are not strictly required.
Examples:
relationship details
character background information
additional context about the crime
Optional evidence enriches the investigation while allowing different players to uncover different levels of detail.

Evidence Comparison
Players can compare evidence items to test hypotheses.
For example:
comparing a shoe print with a suspect’s shoes
matching fingerprints from different objects
linking phone numbers to suspects
When a valid comparison is performed, the system generates a forensic match result.
This mechanic encourages players to actively analyze their evidence rather than simply collecting it.

Progressive Discovery
To prevent players from becoming stuck, the system includes progressive discovery mechanics.
If important evidence is overlooked, later investigation events may draw attention to it.
For example:
a technician may mention a suspicious object
a witness might reference something at the scene
a detective partner might suggest examining a particular area
These nudges ensure progress while preserving the feeling of player-driven discovery.

Investigation Tools
Certain investigative actions require specialized tools.
Possible tools include:
fingerprint powder
UV light
chemical residue tests
Tools unlock deeper layers of analysis and may reveal hidden clues such as:
invisible blood traces
cleaned fingerprints
chemical residues
Tools expand the range of investigative possibilities as the case progresses.

Location Investigation Board
Each location has a local investigation board that records discovered clues.
Objects are represented as nodes, and evidence discovered from those objects is attached to them.
This allows players to track:
which objects were investigated
which examinations were performed
what evidence was discovered
The board acts as a visual representation of the investigation progress within that location.

Design Goals
The Evidence Discovery System is designed to achieve several goals:
Encourage logical thinking
Players must reason about what they examine and how they examine it.
Avoid pixel hunting
Evidence is tied to logical investigation rather than hidden clickable areas.
Reward curiosity
Players who investigate thoroughly will uncover deeper layers of the story.
Support multiple investigation paths
Different players may discover clues in different orders, allowing diverse approaches to solving the case.

Resulting Player Experience
The system creates the experience of conducting a real investigation.
Players will continuously move through the following cycle:
observing the environment
forming investigative questions
performing examinations
discovering evidence
developing new hypotheses
This loop creates a sense of intellectual engagement and makes evidence discovery feel meaningful rather than mechanical.

22. Investigation Economy
Design Goal
Create time pressure and planning without turning the game into a resource-management puzzle.
The player should constantly think:
“What is the best thing to do today?”

Investigation Day Structure
Each day consists of exactly three phases:

Morning — Informational only. New information arrives (lab results, surveillance, story events). Player cannot perform actions. Automatically transitions to Daytime.
Daytime — The only phase where the player can perform actions. The player has 4 actions per day.
Night — Triggered automatically when actions reach 0, or manually via "End Day" button. Processes queued systems (lab, surveillance, delayed events). Automatically transitions to the next day's Morning.

The player gets:

4 actions per day
4 days
= 16 major investigation actions

This creates meaningful planning.

Types of Investigation Actions
Actions consume one action point unless otherwise noted.
Major Actions
Cost: 1 action
Examples:
interrogate suspect
inspect/examine an investigable target at a location
search location
examine digital device
analyze large evidence group

Location Entry
Cost: 0 actions
Examples:
open a location from the map
return to a previously visited location

Passive Actions
Cost: 0 actions
Examples:
reviewing evidence
organizing detective board
building timeline
reading lab reports
These can be done anytime.

Delayed Actions
These start immediately but complete later.
Examples:

This keeps investigation flowing even when the player waits.

Interrogation Time
Interrogations should take one investigation slot.
However:
follow-up questions inside the same interrogation are free
presenting evidence during the interrogation is free
So one interrogation session might contain many exchanges.
This keeps interrogations deep but avoids time micromanagement.

Can the Player Run Out of Time?
My recommendation:
No hard failure.
Instead use soft pressure.
If the player reaches the final day without solving the case:

Chief: "This case needs results tomorrow."

Player gets one final investigation phase.
Then must submit theory.
This prevents frustration.

23. Warrant System
This is where realism and gameplay meet.
We want warrants to feel logical but not bureaucratic.

Evidence Threshold System
Instead of manually writing warrants, the system checks evidence categories.
Example categories:
presence
motive
opportunity
connection

To obtain a warrant, the player must provide evidence from at least two categories.

Example: Searching Julia's Apartment
Player might present:
Fingerprint on wine glass (presence)
Text message to victim (connection)

Judge approves warrant.

Warrant Types
Search Warrant
Allows searching:
homes
offices
vehicles
Unlocks new location evidence pools.

Surveillance Warrant
Allows:
phone taps
hidden cameras
financial monitoring
Results arrive next day.

Digital Warrant
Allows:
phone unlocking
email access
data recovery
Often reveals powerful evidence.

Arrest Warrant
Requires strong evidence:

3+ evidence categories

But arrest does not end the case automatically.
The player still must prove the theory.

Approval System
Warrants are submitted to a judge interface.
Player selects evidence supporting the warrant.
The system evaluates if it meets the threshold.
This creates a mini deduction challenge.


24. Case Conclusion System
This is the most important moment of the entire case.
It must feel like solving a puzzle, not clicking a button.

Final Case Report
At the end of the investigation the player submits a Case Report.
They must answer key questions.
Example:
Who committed the murder?
What was the motive?
What was the weapon?
When did the murder occur?
How did the suspect enter the location?


Evidence Linking
For each answer the player must attach supporting evidence.
Example:
Murderer: Julia Ross
Evidence:
• fingerprint on wine glass
• elevator access log
• shoe print match


Timeline Reconstruction
The player must also complete the final timeline.
Example:
20:40 Mark leaves
20:50 Julia arrives
20:55 argument
21:00 murder
21:05 Julia leaves

If the timeline is wrong, the theory weakens.

Theory Evaluation
The game checks if the theory is logically supported.
Evaluation considers:
evidence consistency
timeline correctness
contradictions
Result categories:
Perfect Solution
Player uncovered nearly all truth.

Correct But Incomplete
Murderer identified but deeper secrets missed.

Incorrect Theory
Evidence contradicts conclusion.
Player may revise.

Why This System Works
It avoids the worst detective game problem:
Click button → game explains solution

Instead the player must prove the case themselves.
Which feels extremely satisfying.

Final System Overview
Investigation Economy
4 actions per day
4 days
16 major investigation actions


Warrant System
Evidence categories determine approval


Case Conclusion
Player submits full theory with evidence


26. The Prosecutor Confidence System
Core Idea
Instead of the player simply “solving” the case, they must convince the prosecutor that the case is strong enough to bring to court.
This introduces a realistic question:
Is the evidence strong enough to convict?
Even if the player knows who the murderer is, the legal case might still be weak.

How It Works
When the player finishes the investigation, they submit their Case Report.
The prosecutor reviews it and calculates a Confidence Score based on:
strength of evidence
consistency of the timeline
absence of contradictions
completeness of the theory
This score determines how confident the prosecutor is in winning the case.

Confidence Levels
Weak Case
The evidence is insufficient.
Prosecutor response example:
“This won’t survive in court. We need stronger evidence.”
The player must return to the investigation.

Moderate Case
The suspect can be charged, but the case is risky.
Example:
“We could take this to trial, but the defense will attack these gaps.”
Player can either:
proceed anyway
gather more evidence

Strong Case
The evidence is solid.
Example:
“This is a strong case. A jury will likely convict.”

Perfect Case
The case is airtight.
Example:
“The defense has nowhere to hide.”
This requires discovering most major evidence in the case.

What Determines Confidence
Confidence is not just about quantity of clues.
The system evaluates several factors.

Evidence Strength
Different evidence types carry different weight.
Example:
Weak evidence:
suspicious behavior
indirect witness testimony
Strong evidence:
fingerprints
DNA
surveillance footage
digital records

Timeline Consistency
If the player builds a clear timeline proving the suspect’s presence at the crime scene, confidence increases significantly.
Timeline contradictions reduce confidence.

Motive Proof
Simply stating the motive is not enough.
The player must attach evidence supporting it.
Example:
Claim: Financial motive
Supporting evidence:
insurance policy
bank transfer
debt records

Alternative Suspects
If other suspects still appear plausible, confidence decreases.
The prosecutor will question unresolved contradictions.
Example:
“You’re accusing Julia, but Mark’s alibi is weak. The defense will exploit that.”
This forces the player to eliminate alternative suspects logically.

Player Choice: Risk vs Certainty
The best part of this system is player choice.
Even with moderate confidence, the player can say:
“Charge the suspect.”
This creates tension.
Possible outcomes:
suspect confesses
trial succeeds
trial fails

Why This Mechanic Is Powerful
It solves several design problems.
1. Realistic justice system
Real investigations are about conviction probability, not absolute truth.

2. Encourages deeper investigation
Players who want the perfect ending will keep digging for more evidence.

3. Creates emotional tension
The final accusation becomes a dramatic moment.

4. Supports replayability
Players may replay cases to achieve a perfect prosecution.

Example Ending Moment
Player submits case.
Prosecutor responds:
“You’ve built a compelling case against Julia Ross.The fingerprints place her at the scene.The elevator logs destroy her alibi.And the insurance policy explains the motive.”
Confidence: 82%
Then the player chooses:
Charge Julia Ross
Gather More Evidence
Review Case

That decision feels heavy.

26. Replayability Features (Future Consideration)
Possible future mechanics include:
procedural case variations
alternate suspects
evidence location randomization
These systems are not planned for the prototype but may appear in later development.

27. Prototype Goal
The purpose of the first prototype case is to validate:
investigation systems
interrogation mechanics
evidence reasoning
timeline reconstruction
The focus is mechanical depth rather than scale.
Once the systems prove effective, additional cases can be developed.
Investigation Data Architecture
The investigation system should be built around five core entity types.
Case
Person
Evidence
Statement
Event

These entities are connected through relationships.
Think of the whole investigation as a graph of information.

Person ---- Statement ---- Evidence
   |           |             |
   |           |             |
   ----- Event ---- Timeline ----

This structure allows:
• contradictions• timeline reconstruction• suspect relationships• evidence linking

1. Case Object
The Case is the root container.
Case Fields
Case
    id
    title
    description
    startDay
    endDay
    suspects[]
    persons[]
    locations[]
    evidence[]
    statements[]
    events[]

The case holds all investigation data.
Example:
Case
    id: murder_001
    title: The Riverside Murder
    days: 4


2. Person Entity
Represents anyone involved in the case.
Not everyone is a suspect.
Person Fields
Person
    id
    name
    role
    personalityTraits
    relationships[]

Example
Person
    id: p_anna
    name: Anna Keller
    role: witness

Possible roles:
victim
suspect
witness
investigator
technician


3. Evidence Entity
Evidence objects are the core gameplay objects.
Evidence Fields
Evidence
    id
    name
    description
    type
    locationFound
    discoveredDay
    relatedPersons[]
    tags[]
    labStatus

Evidence Types
forensic
document
photo
recording
financial
digital
object

Example
Evidence
    id: ev_fingerprint_glass
    name: Fingerprint on whiskey glass
    locationFound: kitchen
    discoveredDay: 1
    relatedPersons: [p_mark]

Important:
Evidence does not automatically prove anything.
It only becomes meaningful when connected to statements or events.

4. Statement Entity
Statements are extremely important because they create lies and contradictions.
Every interrogation produces statements.
Statement Fields
Statement
    id
    person
    text
    dayGiven
    relatedEvidence[]
    relatedEvent

Example
Statement
    id: st_23
    person: p_mark
    text: "I left the house at 20:30."
    dayGiven: 1

Later we might attach evidence:
relatedEvidence: security_camera_footage

This creates the possibility of contradiction detection.

5. Event Entity (Timeline)
Events represent things that happened in the world.
They form the timeline puzzle.
Event Fields
Event
    id
    description
    time
    day
    location
    involvedPersons[]
    supportingEvidence[]

Example
Event
    id: ev_argument
    description: Loud argument heard
    time: 20:45
    day: 1
    location: house

Players reconstruct the timeline using these events.

6. Location Entity
Locations represent investigation areas.
Location Fields
Location
    id
    name
    searchable
    evidencePool[]

Example:
Location
    id: house_kitchen
    name: Victim's Kitchen


7. Relationship System
People have relationships.
Relationship Object
Relationship
    personA
    personB
    type

Types might include:
spouse
coworker
business_partner
friend
enemy
family

Example:

Mark --- business_partner --- Victim

This helps build motives.

8. Investigation Board Data Model
The player's detective board needs its own structure.
Board Node
BoardNode
    id
    type
    referenceID
    notes

Types:
person
evidence
event
statement
location

Board Connection
BoardConnection
    fromNode
    toNode
    label

Example:
Fingerprint -> Mark
label: possible presence

The important rule:
The board is player interpretation, not game truth.
Players can make wrong connections.

9. Lab Processing System
Evidence may enter lab processing.
Lab Request
LabRequest
    id
    evidenceID
    requestType
    daySubmitted
    dayCompleted
    resultEvidence

Example:
LabRequest
    evidenceID: knife_01
    requestType: fingerprint_analysis
    dayCompleted: 2

The result becomes new evidence.

10. Surveillance System
SurveillanceRequest
SurveillanceRequest
    targetPerson
    type
    dayInstalled
    resultEvents[]

Types:
phone_tap
home_surveillance
financial_monitoring

These generate new events or evidence.

11. Mandatory Action System
We also store required investigation tasks.
MandatoryAction
MandatoryAction
    id
    description
    deadlineDay
    completed

Example:
MandatoryAction
    description: Interrogate Anna Keller
    deadlineDay: 1

If not completed, the day cannot advance.

12. Hidden Story Logic
Behind the scenes, the case has true facts.
TrueTimeline
TrueMurderer
TrueMotive
TrueWeapon

The player never sees this directly.
The investigation reveals fragments of it.

13. Example Mini Data Structure
Example simplified case:
Persons
    victim: Daniel Ross
    suspect: Mark Bennett
    suspect: Sarah Klein
    witness: Anna Keller

Evidence
    fingerprint_glass
    security_camera
    phone_records
    bank_transfer

Statements
    Mark: "I left at 20:30"
    Sarah: "I was home"

Events
    20:45 argument heard
    21:05 estimated death

From these pieces the player builds the truth.

Core Gameplay Pillars
Overview
The Core Gameplay Pillars define the fundamental design principles of the detective investigation game. These pillars ensure that every system, mechanic, and feature contributes to the intended player experience.
The game is designed to be a challenging, intellectually engaging investigation experience where players must think critically, analyze evidence, and uncover the truth through reasoning.
The pillars act as guiding rules for development. Any feature that does not support these principles should be reconsidered or removed.

Pillar 1 — Player-Driven Deduction
The player performs the reasoning process.
The game does not automatically solve connections between clues or guide the player toward the correct conclusion.
Evidence, statements, and events are collected and stored, but the player must determine:
what evidence is relevant
which statements are lies
how events connect in the timeline
who had motive, means, and opportunity
The player’s detective board serves as a workspace for organizing and interpreting information, but the game does not automatically interpret evidence for them.
This pillar ensures that solving the case feels like a genuine intellectual achievement.

Pillar 2 — Realistic Investigation Process
Investigations unfold gradually and require time, planning, and evidence.
Players cannot immediately perform every action. Certain investigative steps require prerequisites such as:
sufficient evidence
legal warrants
forensic analysis
surveillance installation
Additionally, many processes take time to complete. For example:
laboratory analysis returns results the next day
surveillance recordings are collected overnight
digital forensic recovery takes time
This system encourages players to plan their investigations carefully and think ahead.

Pillar 3 — Meaningful Evidence
Every piece of evidence has context and potential meaning.
Evidence is not simply a collectible item; it represents a fact about the case that must be interpreted.
Evidence can:
support a theory
contradict a statement
reveal hidden relationships
establish the timeline of events
Importantly, not all evidence directly leads to the solution. Some clues may be misleading, incomplete, or only meaningful when combined with other clues.
This creates a more realistic investigative environment.

Pillar 4 — Psychological Interrogation
Suspects are not passive information sources. They react emotionally and strategically during questioning.
During interrogations, suspects may:
lie to protect themselves
reveal partial truths
deflect questions
become defensive or nervous when confronted with evidence
Presenting the right evidence at the right moment can expose contradictions and pressure suspects into revealing new information.
Interrogations therefore become a strategic interaction between the player and the suspect rather than a simple dialogue tree.

Pillar 5 — Layered Mystery
The investigation reveals multiple layers of hidden information.
At first, the player is solving the apparent crime. As the investigation progresses, deeper secrets emerge, including hidden relationships, financial conflicts, or personal motives.
Each layer adds complexity to the case and reshapes the player’s understanding of events.
This layered approach ensures that the investigation remains engaging and surprising throughout the entire case.

Pillar 6 — Freedom of Investigation
Players are free to pursue leads in different orders and follow different investigative paths.
The game does not enforce a strict sequence of discoveries. Instead, clues and evidence can be uncovered through multiple routes, allowing players to approach the case in their own way.
For example, a player may:
discover timeline contradictions first
uncover financial motives first
expose hidden relationships first
Despite different investigation paths, the evidence ultimately converges on the same truth.

Pillar 7 — Consequences and Time Pressure
The investigation unfolds over multiple in-game days.
Certain events may occur as time passes, such as:
witnesses changing their statements
suspects altering their behavior
new evidence becoming available
Some investigative tasks must be completed within certain timeframes to keep the investigation moving forward.
This creates a sense of urgency and encourages efficient investigative planning.

Pillar 8 — Intellectual Challenge
The game is intentionally designed to be challenging.
Players are not given explicit solutions or constant hints. Instead, the game encourages careful observation, logical reasoning, and evidence analysis.
Solving the case should feel like a genuine accomplishment.
The goal is not to appeal to every player, but to create a memorable experience for players who enjoy complex investigative challenges.

Pillar 9 — Commitment Under Uncertainty
The player must periodically make meaningful investigative judgments before possessing perfect information.
Examples:
- which lead to pursue today
- which evidence is worth lab time
- whether a suspect is lying
- whether to request a warrant
- whether a contradiction is strong enough to confront
- which theory best explains current facts
The player should rarely have complete certainty.
Instead, they must act on probability, interpretation, and strategic confidence.
This creates real detective tension and prevents passive completion-based play.

Pillar Summary
The entire design of the game is built around the following principles:
Player-driven deduction
Realistic investigation process
Meaningful evidence interpretation
Psychological interrogation
Layered mystery storytelling
Freedom of investigation
Consequences and time pressure
Intellectual challenge
These pillars define the identity of the game and guide all future design decisions.

The 5-Layer Mystery Structure
A strong detective case usually contains five stacked mysteries.
Players think they are solving the murder, but every layer reveals a deeper problem.
Layer 1 — The Crime
Layer 2 — The Lies
Layer 3 — Hidden Relationships
Layer 4 — The Secret
Layer 5 — The Truth

Let's break this down.

Layer 1 — The Crime (Surface Mystery)
This is what the player initially investigates.
Example:
A man was murdered in his home.

At this stage the player asks simple questions:
• Who killed him?• What weapon was used?• When did it happen?
Most detective games stop here, which is why they feel shallow.

Layer 2 — The Lies
Now the player starts discovering that people are lying.
Example:
• Suspect says he left at 20:30• Security footage shows 21:10
Players realize:
Something doesn't add up.

The focus shifts from crime solving → lie detection.
This is where interrogation becomes interesting.

Layer 3 — Hidden Relationships
Now the player learns the suspects are connected in unexpected ways.
Example:
• Two suspects secretly know each other• Someone owes money• Someone had an affair
The player realizes:
The people in this case were not strangers.

The investigation becomes social network analysis.

Layer 4 — The Secret
Now the investigation uncovers the real underlying conflict.
Example:
• embezzlement• blackmail• hidden inheritance• illegal business
At this stage the player realizes:
The murder is just the tip of the iceberg.


Layer 5 — The Truth
Finally everything connects.
The player understands:
• real motive• true sequence of events• who manipulated whom• why the murder happened
This final realization creates the detective "aha moment”.


Example Layered Mystery (Simple)
LAYER 1
Victim stabbed in house

LAYER 2
Two suspects lie about where they were

LAYER 3
One suspect secretly dating victim's wife

LAYER 4
Victim discovered illegal financial fraud

LAYER 5
Murder was done to prevent exposure

This is how a story with 25 clues feels like 100 clues.


Our First Prototype Case
Constraints we defined earlier:
4 suspects
5 locations
~25 evidence items
4 investigation days

Let's design something small but strong.

Case Title
The Riverside Apartment Murder

Victim
Name: Daniel Ross
Age: 42
Profession: Financial consultant
Found dead in his apartment
Cause of death: knife wound
Estimated death: 21:00


Suspects
Suspect 1 — Mark Bennett
Business partner of the victim
Financial problems
Claims he left the apartment early

Possible motive: money dispute.

Suspect 2 — Sarah Klein
Victim's neighbor
Heard the argument
Claims she stayed in her apartment

Possible motive: unknown.

Suspect 3 — Julia Ross
Victim's wife
Marriage problems
Was "out with friends"

Possible motive: relationship conflict.

Suspect 4 — Lucas Weber
Building maintenance worker
Has access to apartments
Was working that evening

Possible motive: opportunity.

Locations
1 Victim apartment
2 Building hallway
3 Parking lot
4 Neighbor apartment
5 Victim office


Basic Timeline (Hidden Truth)
This is the actual timeline, not visible to players.
19:30 Mark visits Daniel
20:15 Argument about money
20:40 Mark leaves
20:50 Julia arrives secretly
21:00 Julia kills Daniel
21:10 Sarah hears noise

But players won't see this directly.

Evidence Examples
We aim for about 25 pieces of evidence.
Examples:
Crime Scene
bloody knife
wine glasses (2)
fingerprint on glass
phone on table
broken picture frame

Digital Evidence
phone call log
text message from Julia
bank transfer record
email argument

Witness Evidence
Sarah testimony
parking camera footage
security hallway camera

Physical Evidence
Julia fingerprint on wine glass
Mark fingerprint on desk
maintenance key logs
shoe print in hallway


Key Lies
These will drive interrogations.
Mark: "I left at 20:30"
Julia: "I wasn't there that night"
Sarah: "I didn't see anyone in hallway"
Lucas: "I finished work at 19:00"

Each statement can be contradicted by evidence.

Hidden Relationships (Layer 3)
Later players discover:
Julia and Mark secretly met before
Mark owed Daniel money
Daniel discovered missing funds

Now suspicion spreads.

Layer 4 Secret
The deeper secret:
Daniel discovered Mark was stealing money
Daniel planned to expose him
Julia learned about it
Julia feared financial ruin


Final Truth
Julia killed Daniel during confrontation.
Mark lied because of embezzlement.
Sarah hid information because she feared involvement.
Lucas is mostly innocent.


Key Investigation Moment
One critical discovery could be:
Wine glass with Julia's fingerprint

Combined with:
Julia claiming she was not there

This creates a powerful contradiction.

Day Progression Example
Day 1
Player investigates crime scene.
Evidence discovered:
knife
wine glasses
phone

Mandatory:
interrogate Sarah
interrogate Mark


Day 2
Lab results arrive.
fingerprints
phone records

New contradictions appear.

Day 3
Player gains warrant to search Julia's phone.
New evidence appears:
deleted messages
financial transfers


Day 4
Player assembles final theory.
Accuses murderer.

Why This Case Works
It satisfies the layered structure:
Layer 1 — murder
Layer 2 — suspects lying
Layer 3 — hidden relationships
Layer 4 — financial crime
Layer 5 — emotional motive

And it fits our prototype constraints.

Full Evidence List (25 Clues)
Crime Scene Evidence
E1 — Murder Weapon (Kitchen Knife)Found in victim's kitchen sinkBlood matches victim

E2 — Two Wine Glasses on TableIndicates victim had company

E3 — Julia's Fingerprint on Wine GlassLab result (Day 2)
Contradiction with Julia’s statement.

E4 — Mark's Fingerprint on DeskExplains his earlier visit.

E5 — Broken Picture FramePhoto of Daniel and JuliaSuggests argument.

E6 — Victim's PhoneContains last messages.

Digital Evidence
E7 — Text Message From Julia (20:40)"Are you home? We need to talk."

E8 — Deleted Messages (Recovered Later)Argument between Daniel and Julia.
Unlocked via phone search warrant.

E9 — Call Log Between Mark and DanielMultiple calls about financial issues.

E10 — Email From Daniel to MarkSubject: “We need to fix this before tomorrow.”

Financial Evidence
E11 — Suspicious Bank TransferMoney moved from company account.

E12 — Accounting FilesShows embezzlement pattern.
Found in victim’s office.

E13 — Julia’s Financial RecordsLarge debt.

Surveillance Evidence
E14 — Parking Lot CameraMark leaving building at 20:40.

E15 — Hallway Camera (Blurry Figure)Someone enters apartment at ~20:50.
Height roughly matches Julia.

E16 — Elevator LogsShows Julia’s key card used.

Witness Evidence
E17 — Sarah TestimonyHeard argument around 20:45.

E18 — Sarah Second TestimonyLater admits hearing female voice.
Unlocked after pressure.

E19 — Lucas Work LogMaintenance work until 20:00.

Physical Evidence
E20 — Shoe Print in HallwayMatches Julia’s shoes.
Lab result.

E21 — Julia’s Shoes (Search Warrant)Match hallway print.

E22 — Wine BottleRecently opened.

E23 — Knife Block in KitchenOne knife missing.

Hidden Evidence
E24 — Hidden Safe in OfficeContains documents about embezzlement.

E25 — Daniel's Personal JournalMentions confronting Mark and Julia.

Interrogation Dialogue Triggers
Instead of fixed dialogue trees, interrogations unlock reaction triggers when specific evidence is presented.

Suspect: Mark Bennett
Initial Story

"I visited Daniel earlier but left around 20:30."


Trigger 1 — Parking Camera (E14)
Player shows camera evidence.
Mark reacts:
"Alright… maybe it was closer to 20:40."

Lie exposed but not murder.

Trigger 2 — Financial Records (E11)
Mark becomes defensive.
"This has nothing to do with the murder."

Player learns about embezzlement.

Trigger 3 — Office Safe Documents (E24)
Mark admits truth:
Daniel found out about the missing money.
But I didn't kill him.


Suspect: Sarah Klein
Initial Statement
"I heard some arguing but didn't see anything."


Trigger 1 — Hallway Camera (E15)
Player confronts her.
She becomes nervous.
"I may have heard a woman's voice..."


Trigger 2 — Shoe Print Evidence
She remembers hearing footsteps.
Someone walked past my door quickly.


Suspect: Julia Ross
Initial Story
"I wasn't at the apartment that night."


Trigger 1 — Fingerprint on Wine Glass (E3)
Julia becomes defensive.
I visited earlier in the day.


Trigger 2 — Elevator Log (E16)
She changes story.
Okay… I stopped by briefly.
But Daniel was alive when I left.


Trigger 3 — Shoe Print Match (E20 + E21)
Julia begins to panic.

Trigger 4 — Journal Entry (E25)
Break point.
He threatened to ruin everything.
I just lost control.

Partial confession.

Suspect: Lucas Weber
Lucas acts as a false suspect.

Trigger 1 — Maintenance Logs
Shows he finished work early.

Trigger 2 — Key Access Logs
Proves he didn’t enter apartment.

Lucas becomes a red herring suspect.

Timeline Puzzle
The player reconstructs the evening.
Players must correctly place these events on the timeline board.

Event 1 — Mark Arrives
19:30
Mark visits Daniel.

Evidence:
Mark statement
Fingerprint

Event 2 — Argument About Money
20:15
Daniel confronts Mark.

Evidence:
Email
Financial records

Event 3 — Mark Leaves
20:40
Mark exits building.

Evidence:
Parking camera

Event 4 — Julia Sends Text
20:40
Julia asks if Daniel is home.

Evidence:
Phone record

Event 5 — Julia Arrives
20:50
Julia enters apartment.

Evidence:
Elevator logs
Hallway camera

Event 6 — Loud Argument
20:55
Sarah hears shouting.

Evidence:
Sarah testimony

Event 7 — Murder
21:00
Daniel stabbed.

Evidence:
Autopsy

Event 8 — Julia Leaves
21:05
Footsteps in hallway.

Evidence:
Shoe print
Sarah testimony

Final Deduction
When players connect:
Julia fingerprint
+
Julia presence
+
financial motive
+
timeline

They reach the conclusion:
Julia killed Daniel during confrontation.


Why This Case Is Actually Good
The case allows multiple reasoning paths.
Players can solve it through:
Path 1 — Timeline
Camera → elevator → shoe prints.

Path 2 — Physical evidence
Wine glass → fingerprints → lie.

Path 3 — Motive
Embezzlement → confrontation → emotional reaction.

What Makes This Fun
Players will constantly think they solved the case, then realize:
"Wait… that doesn't explain this clue."

That moment is the core pleasure of detective games.


Visual Style Guide
Overview
The visual style of the game aims to support the core experience of serious investigative work and atmospheric mystery. The visuals should evoke the tone of modern true-crime documentaries and noir-inspired detective fiction while remaining clean and readable for investigation gameplay.
The art direction prioritizes:
clarity for investigation mechanics
strong atmospheric lighting
grounded realism
visual consistency across all assets
The goal is to immerse the player in the role of a professional investigator while keeping the interface and evidence easy to read.

Art Style
The game uses a stylized semi-realistic illustration style rather than full realism.
Characteristics:
painterly textures
slightly simplified shapes
realistic proportions
cinematic composition
visible brush or texture detail
This approach avoids the uncanny valley of hyperrealism while still feeling grounded.
Visually the style should feel similar to a modern noir illustration.
Key traits:
muted colors
soft texture shading
subtle film grain
atmospheric depth
This style works well with AI generation and remains visually cohesive across scenes.

Color Palette
The color palette supports a dark investigative mood while keeping important information readable.
Primary colors:
Deep charcoalMuted navyCold gray
These dominate backgrounds and environments.
Secondary colors:
Desaturated brownsDirty greensMuted beige
Used for interiors and objects.
Accent colors:
Deep redAmber yellowCool cyan
These should be used sparingly for important elements such as:
evidence highlights
interactive UI elements
alerts or warnings
The overall palette should feel cool and subdued, avoiding bright saturated colors.

Lighting Mood
Lighting is one of the most important aspects of the visual identity.
The game uses cinematic investigative lighting inspired by noir films.
Lighting characteristics:
strong directional light
soft shadows
localized light sources
dark surrounding environments
Typical light sources include:
desk lamps
streetlights
neon signs
phone screens
police lights
The lighting should create a feeling of late-night investigation and secrecy.
Scenes should never be fully bright; there should always be some shadow and atmosphere.

UI Style
The user interface should feel like real investigative materials rather than a futuristic interface.
UI elements should resemble:
case files
evidence folders
cork boards
printed documents
sticky notes
photographs
Textures:
paper grain
cardboard board surfaces
tape marks
pen scribbles
Typography should resemble:
official police reports
typewritten documents
handwritten annotations
The UI should balance realistic textures with clean usability so that text remains easily readable.

Suspect Portrait Style
Suspect portraits are a key storytelling element and appear during interrogations and evidence reviews.
Portrait characteristics:
chest-up framing
neutral or dark background
realistic lighting
subtle emotional expressions
Lighting should resemble police interview room lighting:
strong overhead light
soft shadowing
clear facial visibility
Expressions should be subtle rather than exaggerated, including:
nervousness
defensiveness
calm confidence
fatigue
Each suspect should have visual traits that help players remember them, such as:
distinctive hairstyle
unique clothing style
subtle accessories
Portraits should feel like professional character photographs rather than stylized drawings.

Crime Scene Style
Crime scenes are presented as detailed illustrated environments with interactive investigation points.
Scene characteristics:
realistic environments
clutter and lived-in details
natural object placement
environmental storytelling
Examples of visual storytelling details:
knocked-over furniture
partially finished drinks
scattered documents
open windows
footprints or smudges
The environment should tell part of the story before the player even begins investigating.
Crime scenes should be framed from a detective’s observational perspective, allowing the player to visually scan the environment.

Evidence Visual Style
Evidence items should appear as photographed objects rather than stylized icons.
Examples:
close-up fingerprint photo
evidence bag with knife
screenshot of phone messages
surveillance still image
Evidence images should feel like items placed in a real case file.
Many evidence pieces can include:
measurement markers
evidence labels
police tags
timestamps
These small details greatly increase realism.

Environmental Tone
The overall world should feel grounded and believable.
Locations should include everyday environments such as:
apartments
offices
restaurants
parking garages
alleyways
These familiar settings help players relate to the investigation and imagine the events that occurred.

Visual Consistency Rules
To maintain a coherent visual identity, all assets must follow these rules:
consistent lighting direction
consistent color palette
similar texture style
consistent camera perspective
AI-generated images should always be adjusted or regenerated if they break the visual style.
Maintaining consistency is more important than visual complexity.

Visual Priorities
The game’s visual priorities are:
clear investigation readability
strong investigative atmosphere
consistent art style
believable environments
immersive case file presentation
Visual spectacle is not the focus. The visuals exist primarily to support investigation and storytelling.
