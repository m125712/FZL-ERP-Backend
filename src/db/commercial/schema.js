import { sql } from 'drizzle-orm';
import { decimal, integer, pgSchema, text } from 'drizzle-orm/pg-core';
import { DateTime, defaultUUID, uuid_primary } from '../variables.js';

import * as hrSchema from '../hr/schema.js';
import * as publicSchema from '../public/schema.js';
import * as zipperSchema from '../zipper/schema.js';

const commercial = pgSchema('commercial');

export const bank = commercial.table('bank', {
	uuid: uuid_primary,
	name: text('name').notNull(),
	swift_code: text('swift_code').notNull(),
	address: text('address').default(null),
	policy: text('policy').default(null),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	created_by: defaultUUID('created_by').references(() => hrSchema.users.uuid),
	remarks: text('remarks').default(null),
});

export const lc_sequence = commercial.sequence('lc_sequence', {
	startWith: 1,
	increment: 1,
});

export const lc = commercial.table('lc', {
	uuid: uuid_primary,
	party_uuid: defaultUUID('party_uuid').references(
		() => publicSchema.party.uuid
	),
	id: integer('id')
		.default(sql`nextval('commercial.lc_sequence')`)
		.notNull(),
	lc_number: text('lc_number').notNull(),
	lc_date: text('lc_date').notNull(),
	payment_value: decimal('payment_value', {
		precision: 20,
		scale: 4,
	}).default(0),
	payment_date: DateTime('payment_date').default(null),
	ldbc_fdbc: text('ldbc_fdbc').default(null),
	acceptance_date: DateTime('acceptance_date').default(null),
	maturity_date: DateTime('maturity_date').default(null),
	commercial_executive: text('commercial_executive').notNull(),
	party_bank: text('party_bank').notNull(),
	production_complete: integer('production_complete').default(0),
	lc_cancel: integer('lc_cancel').default(0),
	handover_date: DateTime('handover_date').default(null),
	document_receive_date: DateTime('document_receive_date').default(null),
	shipment_date: DateTime('shipment_date').default(null),
	expiry_date: DateTime('expiry_date').default(null),
	ud_no: text('ud_no').default(null),
	ud_received: text('ud_received').default(null),
	at_sight: text('at_sight').notNull(),
	amd_date: DateTime('amd_date').default(null),
	amd_count: integer('amd_count').default(0),
	problematical: integer('problematical').default(0),
	epz: integer('epz').default(0),
	created_by: defaultUUID('created_by').references(() => hrSchema.users.uuid),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export const order_info_sequence = commercial.sequence('pi_sequence', {
	startWith: 1,
	increment: 1,
});

export const pi = commercial.table('pi', {
	uuid: uuid_primary,
	id: integer('id')
		.default(sql`nextval('commercial.pi_sequence')`)
		.notNull(),
	lc_uuid: defaultUUID('lc_uuid')
		.default(null)
		.references(() => lc.uuid),
	order_info_uuids: text('order_info_uuids').notNull(),
	marketing_uuid: defaultUUID('marketing_uuid').references(
		() => publicSchema.marketing.uuid
	),
	party_uuid: defaultUUID('party_uuid').references(
		() => publicSchema.party.uuid
	),
	merchandiser_uuid: defaultUUID('merchandiser_uuid').references(
		() => publicSchema.merchandiser.uuid
	),
	factory_uuid: defaultUUID('factory_uuid').references(
		() => publicSchema.factory.uuid
	),
	bank_uuid: defaultUUID('bank_uuid').references(() => bank.uuid),
	validity: integer('validity').notNull(),
	payment: integer('payment').notNull(),
	created_by: defaultUUID('created_by').references(() => hrSchema.users.uuid),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export const pi_entry = commercial.table('pi_entry', {
	uuid: uuid_primary,
	pi_uuid: defaultUUID('pi_uuid').references(() => pi.uuid),
	sfg_uuid: defaultUUID('sfg_uuid').references(() => zipperSchema.sfg.uuid),
	pi_quantity: decimal('pi_quantity', {
		precision: 20,
		scale: 4,
	}).notNull(),
	created_at: DateTime('created_at').notNull(),
	updated_at: DateTime('updated_at').default(null),
	remarks: text('remarks').default(null),
});

export default commercial;
