package com.buggy.order;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "orders")
public class Order {

    @Id
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "restaurant_id", nullable = false)
    private UUID restaurantId;

    @Column(nullable = false)
    private String status;

    @Column(name = "total_minor", nullable = false)
    private long totalMinor;

    @Column(nullable = false)
    private String currency;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "delivery_address", nullable = false, columnDefinition = "jsonb")
    private String deliveryAddress;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Version
    @Column(nullable = false)
    private Long version;

    protected Order() {
    }

    public Order(UUID id, UUID customerId, UUID restaurantId, long totalMinor, String currency,
            String deliveryAddress, Instant createdAt) {
        this.id = id;
        this.customerId = customerId;
        this.restaurantId = restaurantId;
        this.status = "PendingPayment";
        this.totalMinor = totalMinor;
        this.currency = currency;
        this.deliveryAddress = deliveryAddress;
        this.createdAt = createdAt;
    }

    public UUID getId() {
        return id;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public UUID getRestaurantId() {
        return restaurantId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public long getTotalMinor() {
        return totalMinor;
    }

    public String getCurrency() {
        return currency;
    }

    public String getDeliveryAddress() {
        return deliveryAddress;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Long getVersion() {
        return version;
    }
}
