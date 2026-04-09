"""add photo_url and reset token columns to users

Revision ID: 20260409_0001
Revises: 762296c14907
Create Date: 2026-04-09
"""

from alembic import op
import sqlalchemy as sa


revision = "20260409_0001"
down_revision = "762296c14907"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("photo_url", sa.String(), nullable=True))
    op.add_column("users", sa.Column("reset_token", sa.String(), nullable=True))
    op.add_column("users", sa.Column("reset_token_expires", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "reset_token_expires")
    op.drop_column("users", "reset_token")
    op.drop_column("users", "photo_url")
