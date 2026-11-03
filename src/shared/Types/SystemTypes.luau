--!strict

local SystemTypes = {}

export type PropType = "Plank" | "Ball" | "Crate" | "Cylinder" | "Wedge" | "Cash" | "TNT"

export type ToolName =

	"Grab"

	| "Weld"

	| "Rope"

	| "Hinge"

	| "Motor"

	| "Thruster"

	| "Transform"

	| "Paint"

	| "Delete"

	| "Balloon"

	| "Magnet"

export type PropConfig = {

	name: PropType,

	partType: "Block" | "Ball" | "Cylinder" | "Wedge",

	defaultSize: Vector3,

	minSize: Vector3,

	maxSize: Vector3,

	material: Enum.Material,

	color: Color3,

	density: number,

	friction: number,

	elasticity: number,

}

export type ConstraintRecord = {

	id: string,

	constraintType: "WeldConstraint" | "RopeConstraint" | "HingeConstraint" | "Motor" | "Thruster",

	partA: BasePart,

	partB: BasePart?,

	attachment0: Attachment?,

	attachment1: Attachment?,

	instance: Instance,

	ownerId: number,

	meta: { [string]: any },

}

export type UndoActionType =

	"SPAWN_PROP"

	| "DELETE_PROP"

	| "CREATE_CONSTRAINT"

	| "DELETE_CONSTRAINT"

	| "TRANSFORM_PROP"

	| "PAINT_PROP"

export type UndoRecord = {

	actionType: UndoActionType,

	timestamp: number,

	data: { [string]: any },

}

export type SerializedProp = {

	propType: PropType,

	relCFrame: { number }, -- cframe components

	size: { number }, -- x, y, z

	color: { number }, -- rgb 0-255

	material: string,

	anchored: boolean,

}

export type SerializedConstraint = {

	constraintType: string,

	partIndexA: number,

	partIndexB: number,

	attCFrame0: { number }?,

	attCFrame1: { number }?,

	properties: { [string]: any },

}

export type SerializedSaveData = {

	version: number,

	name: string,

	savedAt: number,

	props: { SerializedProp },

	constraints: { SerializedConstraint },

}

return SystemTypes
