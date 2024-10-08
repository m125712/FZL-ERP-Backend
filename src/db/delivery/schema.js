import { decimal, integer, pgSchema, text, uuid } from 'drizzle-orm/pg-core';
import e from 'express';
import * as hrSchema from '../hr/schema.js';
import { DateTime, defaultUUID, uuid_primary } from '../variables.js';
import * as zipperSchema from '../zipper/schema.js';

const delivery = pgSchema('delivery');

export const packing_list = delivery.table('packing_list', {
	uuid: uuid_primary,
	carton_size: text('carton_size').notNull(),
	carton_weight: text('carton_weight').notNull(),
	created_by: defaultUUID('created_by'),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export const packing_list_entry = delivery.table('packing_list_entry', {
	uuid: uuid_primary,
	packing_list_uuid: defaultUUID('packing_list_uuid').references(
		() => packing_list.uuid
	),
	sfg_uuid: defaultUUID('sfg_uuid').references(() => zipperSchema.sfg.uuid),
	quantity: decimal('quantity', {
		precision: 20,
		scale: 4,
	}).notNull(),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export const challan = delivery.table('challan', {
	uuid: uuid_primary,
	carton_quantity: integer('carton_quantity').notNull(),
	assign_to: defaultUUID('assign_to').references(() => hrSchema.users.uuid),
	receive_status: integer('receive_status').default(0),
	created_by: defaultUUID('created_by').references(() => hrSchema.users.uuid),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export const challan_entry = delivery.table('challan_entry', {
	uuid: uuid_primary,
	challan_uuid: defaultUUID('challan_uuid').references(() => challan.uuid),
	packing_list_uuid: defaultUUID('packing_list_uuid').references(
		() => packing_list.uuid
	),
	delivery_quantity: decimal('delivery_quantity', {
		precision: 20,
		scale: 4,
	}).notNull(),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export default delivery;
