from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base

class MonitoredProduct(Base):
    __tablename__ = "monitored_products"
    id = Column(Integer, primary_key=True, index=True)
    url = Column(String, nullable=False)
    site = Column(String, nullable=False, default="generic")
    title = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    price = Column(String, nullable=True)
    price_original = Column(String, nullable=True)
    discount_pct = Column(Integer, nullable=True)
    status = Column(String, nullable=False, default="unknown")
    ever_in_stock = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    check_interval_seconds = Column(Integer, default=60)
    last_checked = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    alerts = relationship("AlertEvent", back_populates="product", cascade="all, delete-orphan")
    price_history = relationship("PriceHistory", back_populates="product", cascade="all, delete-orphan")

class AlertEvent(Base):
    __tablename__ = "alert_events"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("monitored_products.id"), nullable=False)
    event_type = Column(String, nullable=False)
    old_value = Column(String, nullable=True)
    new_value = Column(String, nullable=True)
    notified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    product = relationship("MonitoredProduct", back_populates="alerts")

class PriceHistory(Base):
    __tablename__ = "price_history"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("monitored_products.id"), nullable=False)
    price = Column(String, nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    product = relationship("MonitoredProduct", back_populates="price_history")

class AppSettings(Base):
    __tablename__ = "app_settings"
    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, nullable=False)
    value = Column(Text, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SaleLedger(Base):
    __tablename__ = "sale_ledger"
    id = Column(Integer, primary_key=True, index=True)
    product_title = Column(String, nullable=False)
    buy_price = Column(String, nullable=False)
    sell_price = Column(String, nullable=False)
    fees = Column(String, nullable=False)
    postage = Column(String, nullable=False)
    net_profit = Column(String, nullable=False)
    sold_at = Column(DateTime, default=datetime.utcnow)
