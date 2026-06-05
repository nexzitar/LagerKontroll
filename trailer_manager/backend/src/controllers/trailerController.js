const pool = require('../config/database');
const { formatPlate } = require('../utils/licensePlate');

// Create a new trailer entry
exports.createTrailerEntry = async (req, res, next) => {
  try {
    const {
      trailerNumber,
      terminal,
      isEmpty,
      isInRamp,
      rampNumber,
      latitude,
      longitude,
      address,
      notes,
    } = req.body;

    // Validation
    if (!trailerNumber || !terminal || isEmpty === undefined || !latitude || !longitude) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Missing required fields: trailerNumber, terminal, isEmpty, latitude, longitude',
      });
    }

    // Terminal validation - just check it's not empty
    if (!terminal || terminal.trim().length === 0) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Terminal/location cannot be empty',
      });
    }

    // Ramp validation - if isInRamp is true, rampNumber must be provided
    if (isInRamp === true || isInRamp === 'true') {
      if (!rampNumber || rampNumber.trim().length === 0) {
        return res.status(400).json({
          error: 'Validation failed',
          message: 'Ramp number is required when trailer is in ramp',
        });
      }
    }

    if (!req.processedImage) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Photo is required',
      });
    }

    // Get user ID from auth middleware (optional - may be null if not authenticated)
    const createdBy = req.user?.userId || null;

    // Format the trailer number consistently (e.g., "VA1948" -> "VA 1948")
    const formattedTrailerNumber = formatPlate(trailerNumber.trim());

    // Insert into database
    const result = await pool.query(
      `INSERT INTO trailer_entries
       (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, address, photo_url, thumbnail_url, notes, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        formattedTrailerNumber,
        terminal,
        isEmpty === 'true' || isEmpty === true,
        isInRamp === 'true' || isInRamp === true,
        (isInRamp === 'true' || isInRamp === true) && rampNumber ? rampNumber.trim() : null,
        parseFloat(latitude),
        parseFloat(longitude),
        address || null,
        req.processedImage.url,
        req.processedImage.thumbnailUrl,
        notes || null,
        createdBy,
      ]
    );

    const entry = result.rows[0];

    // Get user name if entry was created by a user
    let createdByName = null;
    if (entry.created_by) {
      const userResult = await pool.query(
        'SELECT name FROM users WHERE id = $1',
        [entry.created_by]
      );
      if (userResult.rows.length > 0) {
        createdByName = userResult.rows[0].name;
      }
    }

    res.status(201).json({
      id: entry.id,
      trailerNumber: entry.trailer_number,
      terminal: entry.terminal,
      isEmpty: entry.is_empty,
      isInRamp: entry.is_in_ramp,
      rampNumber: entry.ramp_number,
      latitude: parseFloat(entry.latitude),
      longitude: parseFloat(entry.longitude),
      address: entry.address,
      photoUrl: entry.photo_url,
      thumbnailUrl: entry.thumbnail_url,
      notes: entry.notes,
      createdBy: createdByName,
      createdAt: entry.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Get all trailers (latest entries)
exports.getTrailers = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 1000,
      trailerNumber,
      terminal,
      isEmpty,
      sortBy = 'date',
      sortDirection = 'desc',
    } = req.query;

    const offset = (page - 1) * limit;
    let query = `SELECT t.*, u.name as created_by_name
                 FROM trailers_latest t
                 LEFT JOIN users u ON t.created_by = u.id
                 WHERE 1=1`;
    const params = [];
    let paramCount = 1;

    // Filters
    if (trailerNumber) {
      query += ` AND trailer_number ILIKE $${paramCount}`;
      params.push(`%${trailerNumber}%`);
      paramCount++;
    }

    if (terminal) {
      query += ` AND terminal = $${paramCount}`;
      params.push(terminal);
      paramCount++;
    }

    if (isEmpty !== undefined) {
      query += ` AND is_empty = $${paramCount}`;
      params.push(isEmpty === 'true');
      paramCount++;
    }

    // Sorting
    const sortColumn = sortBy === 'name' ? 'trailer_number' : 'created_at';
    const direction = sortDirection.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    query += ` ORDER BY ${sortColumn} ${direction}`;

    // Pagination
    query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), offset);

    const result = await pool.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM trailers_latest WHERE 1=1';
    const countParams = [];
    let countParamNum = 1;

    if (trailerNumber) {
      countQuery += ` AND trailer_number ILIKE $${countParamNum}`;
      countParams.push(`%${trailerNumber}%`);
      countParamNum++;
    }

    if (terminal) {
      countQuery += ` AND terminal = $${countParamNum}`;
      countParams.push(terminal);
      countParamNum++;
    }

    if (isEmpty !== undefined) {
      countQuery += ` AND is_empty = $${countParamNum}`;
      countParams.push(isEmpty === 'true');
    }

    const countResult = await pool.query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    // Get summary counts (empty vs loaded vs in ramp)
    let summaryQuery = 'SELECT is_empty, is_in_ramp, COUNT(*) as count FROM trailers_latest WHERE 1=1';
    const summaryParams = [];
    let summaryParamNum = 1;

    if (trailerNumber) {
      summaryQuery += ` AND trailer_number ILIKE $${summaryParamNum}`;
      summaryParams.push(`%${trailerNumber}%`);
      summaryParamNum++;
    }

    if (terminal) {
      summaryQuery += ` AND terminal = $${summaryParamNum}`;
      summaryParams.push(terminal);
      summaryParamNum++;
    }

    if (isEmpty !== undefined) {
      summaryQuery += ` AND is_empty = $${summaryParamNum}`;
      summaryParams.push(isEmpty === 'true');
    }

    summaryQuery += ' GROUP BY is_empty, is_in_ramp';

    const summaryResult = await pool.query(summaryQuery, summaryParams);

    let emptyCount = 0;
    let loadedCount = 0;
    let inRampCount = 0;

    summaryResult.rows.forEach(row => {
      if (row.is_in_ramp) {
        inRampCount += parseInt(row.count);
      } else if (row.is_empty) {
        emptyCount += parseInt(row.count);
      } else {
        loadedCount += parseInt(row.count);
      }
    });

    const trailers = result.rows.map((row) => ({
      id: row.trailer_number,
      trailerNumber: row.trailer_number,
      latestEntry: {
        id: row.latest_entry_id,
        trailerNumber: row.trailer_number,
        terminal: row.terminal,
        isEmpty: row.is_empty,
        isInRamp: row.is_in_ramp,
        rampNumber: row.ramp_number,
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        address: row.address,
        photoUrl: row.photo_url,
        thumbnailUrl: row.thumbnail_url,
        notes: row.notes,
        createdBy: row.created_by_name,
        createdAt: row.created_at,
      },
      entryCount: parseInt(row.entry_count) || 0,
      firstSeenAt: row.first_seen_at || row.created_at,
      lastSeenAt: row.created_at,
    }));

    res.json({
      data: trailers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      summary: {
        emptyCount,
        loadedCount,
        inRampCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get a specific trailer's latest entry
exports.getTrailerById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT t.*, u.name as created_by_name
       FROM trailers_latest t
       LEFT JOIN users u ON t.created_by = u.id
       WHERE trailer_number = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Trailer ${id} not found`,
      });
    }

    const row = result.rows[0];

    res.json({
      id: row.trailer_number,
      trailerNumber: row.trailer_number,
      latestEntry: {
        id: row.latest_entry_id,
        trailerNumber: row.trailer_number,
        terminal: row.terminal,
        isEmpty: row.is_empty,
        isInRamp: row.is_in_ramp,
        rampNumber: row.ramp_number,
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        address: row.address,
        photoUrl: row.photo_url,
        thumbnailUrl: row.thumbnail_url,
        notes: row.notes,
        createdBy: row.created_by_name,
        createdAt: row.created_at,
      },
      entryCount: parseInt(row.entry_count) || 0,
      firstSeenAt: row.first_seen_at || row.created_at,
      lastSeenAt: row.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Get trailer history
exports.getTrailerHistory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { limit = 10, offset = 0 } = req.query;

    // Get total count for pagination
    const countResult = await pool.query(
      `SELECT COUNT(*) FROM trailer_entries WHERE trailer_number = $1`,
      [id]
    );
    const total = parseInt(countResult.rows[0].count);

    const result = await pool.query(
      `SELECT t.*, u.name as created_by_name
       FROM trailer_entries t
       LEFT JOIN users u ON t.created_by = u.id
       WHERE t.trailer_number = $1
       ORDER BY t.created_at DESC
       LIMIT $2 OFFSET $3`,
      [id, parseInt(limit), parseInt(offset)]
    );

    const history = result.rows.map((row) => ({
      id: row.id,
      trailerNumber: row.trailer_number,
      terminal: row.terminal,
      isEmpty: row.is_empty,
      isInRamp: row.is_in_ramp,
      rampNumber: row.ramp_number,
      latitude: parseFloat(row.latitude),
      longitude: parseFloat(row.longitude),
      address: row.address,
      photoUrl: row.photo_url,
      thumbnailUrl: row.thumbnail_url,
      notes: row.notes,
      createdBy: row.created_by_name,
      createdAt: row.created_at,
    }));

    res.json({
      data: history,
      pagination: {
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: offset + history.length < total,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Update trailer status (creates new entry without new photo)
exports.updateTrailerStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      terminal,
      isEmpty,
      isInRamp,
      rampNumber,
      latitude,
      longitude,
      address,
      notes,
    } = req.body;

    // Validation
    if (isEmpty === undefined || !latitude || !longitude) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Missing required fields: isEmpty, latitude, longitude',
      });
    }

    // Ramp validation - if isInRamp is true, rampNumber must be provided
    if (isInRamp === true || isInRamp === 'true') {
      if (!rampNumber || rampNumber.trim().length === 0) {
        return res.status(400).json({
          error: 'Validation failed',
          message: 'Ramp number is required when trailer is in ramp',
        });
      }
    }

    // Get the latest entry to reuse the photo
    const latestEntry = await pool.query(
      `SELECT photo_url, thumbnail_url, terminal FROM trailer_entries
       WHERE trailer_number = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [id]
    );

    if (latestEntry.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Trailer ${id} not found`,
      });
    }

    const { photo_url, thumbnail_url, terminal: latestTerminal } = latestEntry.rows[0];
    const finalTerminal = terminal || latestTerminal;

    // Get user ID from auth middleware (optional - may be null if not authenticated)
    const createdBy = req.user?.userId || null;

    // Insert new entry with reused photo
    const result = await pool.query(
      `INSERT INTO trailer_entries
       (trailer_number, terminal, is_empty, is_in_ramp, ramp_number, latitude, longitude, address, photo_url, thumbnail_url, notes, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        id.trim().toUpperCase(),
        finalTerminal,
        isEmpty === 'true' || isEmpty === true,
        isInRamp === 'true' || isInRamp === true,
        (isInRamp === 'true' || isInRamp === true) && rampNumber ? rampNumber.trim() : null,
        parseFloat(latitude),
        parseFloat(longitude),
        address || null,
        photo_url,
        thumbnail_url,
        notes || null,
        createdBy,
      ]
    );

    const entry = result.rows[0];

    // Get user name if entry was created by a user
    let createdByName = null;
    if (entry.created_by) {
      const userResult = await pool.query(
        'SELECT name FROM users WHERE id = $1',
        [entry.created_by]
      );
      if (userResult.rows.length > 0) {
        createdByName = userResult.rows[0].name;
      }
    }

    res.status(201).json({
      id: entry.id,
      trailerNumber: entry.trailer_number,
      terminal: entry.terminal,
      isEmpty: entry.is_empty,
      isInRamp: entry.is_in_ramp,
      rampNumber: entry.ramp_number,
      latitude: parseFloat(entry.latitude),
      longitude: parseFloat(entry.longitude),
      address: entry.address,
      photoUrl: entry.photo_url,
      thumbnailUrl: entry.thumbnail_url,
      notes: entry.notes,
      createdBy: createdByName,
      createdAt: entry.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Update trailer number (rename trailer, merges if target exists)
exports.updateTrailerNumber = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { newTrailerNumber } = req.body;

    // Validation
    if (!newTrailerNumber || newTrailerNumber.trim().length < 3) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'New trailer number must be at least 3 characters',
      });
    }

    const normalizedNewNumber = formatPlate(newTrailerNumber.trim());

    // Check if source trailer exists
    const checkResult = await pool.query(
      'SELECT COUNT(*) FROM trailer_entries WHERE trailer_number = $1',
      [id]
    );

    if (parseInt(checkResult.rows[0].count) === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Trailer ${id} not found`,
      });
    }

    // Check if new trailer number already exists (will merge if so)
    let merged = false;
    if (normalizedNewNumber !== id.toUpperCase()) {
      const existingResult = await pool.query(
        'SELECT COUNT(*) FROM trailer_entries WHERE trailer_number = $1',
        [normalizedNewNumber]
      );
      merged = parseInt(existingResult.rows[0].count) > 0;
    }

    // Update all entries with the new trailer number (this merges histories if target exists)
    const updateResult = await pool.query(
      'UPDATE trailer_entries SET trailer_number = $1 WHERE trailer_number = $2 RETURNING id',
      [normalizedNewNumber, id]
    );

    const message = merged
      ? `Trailer ${id} merged into ${normalizedNewNumber}`
      : `Trailer renamed from ${id} to ${normalizedNewNumber}`;

    res.json({
      message,
      updatedEntries: updateResult.rows.length,
      newTrailerNumber: normalizedNewNumber,
      merged,
    });
  } catch (error) {
    next(error);
  }
};

// Delete a trailer and all its entries (admin only)
exports.deleteTrailer = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if trailer exists
    const checkResult = await pool.query(
      'SELECT COUNT(*) FROM trailer_entries WHERE trailer_number = $1',
      [id]
    );

    const count = parseInt(checkResult.rows[0].count);

    if (count === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Trailer ${id} not found`,
      });
    }

    // Delete all entries for this trailer
    const deleteResult = await pool.query(
      'DELETE FROM trailer_entries WHERE trailer_number = $1 RETURNING id',
      [id]
    );

    res.json({
      message: `Trailer ${id} deleted successfully`,
      deletedEntries: deleteResult.rows.length,
    });
  } catch (error) {
    next(error);
  }
};
