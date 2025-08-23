package com.example.trialpaymentapp.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface VoucherDao {

    @Query("SELECT * FROM vouchers WHERE isSynced = 0")
    suspend fun getUnsyncedVouchers(): List<Voucher>

    @Query("UPDATE vouchers SET isSynced = 1 WHERE id = :id")
    suspend fun markAsSynced(id: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(vouchers: List<Voucher>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVoucher(voucher: Voucher)

    @Update
    suspend fun updateVoucher(voucher: Voucher)

    @Query("SELECT * FROM vouchers WHERE status = :status ORDER BY timestamp DESC")
    fun getVouchersByStatus(status: String): Flow<List<Voucher>>

    @Query("UPDATE vouchers SET isSynced = :syncedStatus WHERE id = :voucherId")
    suspend fun updateVoucherSynced(voucherId: String, syncedStatus: Boolean)

    @Query("DELETE FROM vouchers WHERE id = :voucherId")
    suspend fun deleteVoucher(voucherId: String)
    @Query("UPDATE vouchers SET isSynced = :isSynced WHERE id = :voucherId")
    suspend fun markVoucherSynced(voucherId: String, isSynced: Boolean)
}
