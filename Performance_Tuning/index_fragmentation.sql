-- Enter Tablespace Name (Line39) or mention Schema Name adding u.name=''
set lines 500 pages 1000
col NEW_IDX_percentage 999.99999
col idxname format a38 head "Owner.Index"
col uniq format a01 head "U"
col tsname format a28 head "Tablespace"
col xtrblk format 99999999 head "Extra|Blocks"
col lfcnt format 99999999 head "Leaf|Blocks"
col blk format 99999999 head "Curr|Blocks"
col currmb format 9999999 head "Curr|MB"
col newmb format 9999999 head "New|MB"
	SELECT
        u.name || '.' || o.name                                                                                     idxname,
        decode(bitand(i.property, 1), 0, ' ', 1, 'x','?')                                                        	uniq,
        ts.name                                                                                                  	tsname,
        seg.blocks                                                                                               	blk,
        i.leafcnt                                                                                                	lfcnt,
        floor((1 - i.pctfree$ / 100) * i.leafcnt - i.rowcnt *(SUM(h.avgcln) + 11) /(8192 - 66 - i.initrans * 24))	xtrblk,
        round(seg.bytes /(1024 * 1024))                                                                          	currmb,
        ( 1 + i.pctfree$ / 100 ) * ( i.rowcnt * ( SUM(h.avgcln) + 11 ) / ( i.leafcnt * ( 8192 - 66 - i.initrans * 24 ) ) * seg.bytes / ( 1024 *
        1024 ) )                                                       newmb,
        ( ( 1 + i.pctfree$ / 100 ) * ( i.rowcnt * ( SUM(h.avgcln) + 11 ) / ( i.leafcnt * ( 8192 - 66 - i.initrans * 24 ) ) * seg.bytes / (
        1024 * 1024 ) ) ) * 100 / ( seg.bytes / ( 1024 * 1024 ) )           new_idx_percentage,
        ( 100 - ( ( 1 + i.pctfree$ / 100 ) * ( i.rowcnt * ( SUM(h.avgcln) + 11 ) / ( i.leafcnt * ( 8192 - 66 - i.initrans * 24 ) ) * seg.
        bytes / ( 1024 * 1024 ) ) ) * 100 / ( seg.bytes / ( 1024 * 1024 ) ) ) benifit_percent
    FROM
        sys.ind$       i,
        sys.icol$      ic,
        sys.hist_head$ h,
        sys.obj$       o,
        sys.user$      u,
        sys.ts$        ts,
        dba_segments   seg
    WHERE
            i.leafcnt > 1
			AND ts.name='DCP11G_DW_IDX'
        AND i.type# IN ( 1, 4, 6 )
        AND -- exclude special types
         ic.obj# = i.obj#
        AND h.obj# = i.bo#
        AND h.intcol# = ic.intcol#
        AND o.obj# = i.obj#
        AND o.owner# != 0
        AND u.user# = o.owner#
        AND i.ts# = ts.ts#
        AND u.name = seg.owner
        AND o.name = seg.segment_name
        AND seg.blocks > i.leafcnt -- if i.leafcnt > seg.blocks then statistics are not up-to-date
    GROUP BY
        u.name,
        decode(bitand(i.property, 1), 0, ' ', 1, 'x',
               '?'),
        ts.name,
        o.name,
        i.rowcnt,
        i.leafcnt,
        i.initrans,
        i.pctfree$,
    --p.value,
        i.blevel,
        i.leafcnt,
        seg.bytes,
        i.pctfree$,
        i.initrans,
        seg.blocks
    HAVING 50 * i.rowcnt * ( SUM(h.avgcln) + 11 ) < ( i.leafcnt * ( 8192 - 66 - i.initrans * 24 ) ) * ( 50 - i.pctfree$ )
           AND floor((1 - i.pctfree$ / 100) * i.leafcnt - i.rowcnt *(SUM(h.avgcln) + 11) /(8192 - 66 - i.initrans * 24)) > 0
           AND ( ( 1 + i.pctfree$ / 100 ) * ( i.rowcnt * ( SUM(h.avgcln) + 11 ) / ( i.leafcnt * ( 8192 - 66 - i.initrans * 24 ) ) * seg.bytes / (
           1024 * 1024 ) ) ) * 100 / ( seg.bytes / ( 1024 * 1024 ) ) < 80
           AND round(seg.bytes /(1024 * 1024)) > 50
    ORDER BY
        10,
        9,
        2;