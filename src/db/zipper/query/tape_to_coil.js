import { eq } from 'drizzle-orm';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import * as hrSchema from '../../hr/schema.js';
import db from '../../index.js';
import { tape_coil, tape_to_coil } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const tapeToCoilPromise = db
		.insert(tape_to_coil)
		.values(req.body)
		.returning({ insertedId: tape_to_coil.uuid });

	try {
		const data = await tapeToCoilPromise;
		const toast = {
			status: 201,
			type: 'insert',
			message: `${data[0].insertedId} inserted`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const tapeToCoilPromise = db
		.update(tape_to_coil)
		.set(req.body)
		.where(eq(tape_to_coil.uuid, req.params.uuid))
		.returning({ updatedId: tape_to_coil.uuid });

	try {
		const data = await tapeToCoilPromise;
		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedId} updated`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const tapeToCoilPromise = db
		.delete(tape_to_coil)
		.where(eq(tape_to_coil.uuid, req.params.uuid))
		.returning({ deletedId: tape_to_coil.uuid });
	try {
		const data = await tapeToCoilPromise;
		const toast = {
			status: 201,
			type: 'delete',
			message: `${data[0].deletedId} deleted`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const resultPromise = db
		.select({
			uuid: tape_to_coil.uuid,
			tape_coil_uuid: tape_to_coil.tape_coil_uuid,
			tape_type: tape_coil.type,
			trx_quantity: tape_to_coil.trx_quantity,
			created_by: tape_to_coil.created_by,
			user_name: hrSchema.users.name,
			user_designation: hrSchema.designation.designation,
			user_department: hrSchema.department.department,
			created_at: tape_to_coil.created_at,
			update_at: tape_to_coil.updated_at,
			remarks: tape_to_coil.remarks,
		})
		.from(tape_to_coil)
		.leftJoin(tape_coil, eq(tape_to_coil.tape_coil_uuid, tape_coil.uuid))
		.leftJoin(
			hrSchema.users,
			eq(tape_to_coil.created_by, hrSchema.users.uuid)
		)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.leftJoin(
			hrSchema.department,
			eq(hrSchema.designation.department_uuid, hrSchema.department.uuid)
		);
	const toast = {
		status: 200,
		type: 'select_all',
		message: 'tape_to_coil list',
	};
	handleResponse({ promise: resultPromise, res, next, ...toast });
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const tapeToCoilPromise = db
		.select({
			uuid: tape_to_coil.uuid,
			tape_coil_uuid: tape_to_coil.tape_coil_uuid,
			tape_type: tape_coil.type,
			trx_quantity: tape_to_coil.trx_quantity,
			created_by: tape_to_coil.created_by,
			user_name: hrSchema.users.name,
			user_designation: hrSchema.designation.designation,
			user_department: hrSchema.department.department,
			created_at: tape_to_coil.created_at,
			update_at: tape_to_coil.updated_at,
			remarks: tape_to_coil.remarks,
		})
		.from(tape_to_coil)
		.leftJoin(tape_coil, eq(tape_to_coil.tape_coil_uuid, tape_coil.uuid))
		.leftJoin(
			hrSchema.users,
			eq(tape_to_coil.created_by, hrSchema.users.uuid)
		)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.leftJoin(
			hrSchema.department,
			eq(hrSchema.designation.department_uuid, hrSchema.department.uuid)
		)
		.where(eq(tape_to_coil.uuid, req.params.uuid));
	const toast = {
		status: 200,
		type: 'select',
		message: 'tape_to_coil',
	};
	handleResponse({ promise: tapeToCoilPromise, res, next, ...toast });
}
