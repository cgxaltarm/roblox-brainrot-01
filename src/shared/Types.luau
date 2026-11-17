-- Types: the shapes of state shared between the server systems.
-- The server owns all of it; the client only renders what the server sends.
export type PlacedBrainrot = {
	CharacterName: string,
	Mutation: string,
	Slot: number,
	Model: Model?,
}

export type PlayerState = {
	Cash: number,
	RebirthLevel: number,
	Placed: { PlacedBrainrot },
	Carrying: string?,
	CarryingMutation: string?,
	LockUntil: number,
	LockCooldownUntil: number,
}

export type ConveyorSlot = {
	CharacterName: string,
	Mutation: string,
	Cost: number,
}

return nil
