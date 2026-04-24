"""add extended profile fields

Revision ID: 20260424_0002
Revises: 20260424_0001
Create Date: 2026-04-24 01:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = '20260424_0002'
down_revision = '20260424_0001'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('religion', sa.String(), nullable=True))
    op.add_column('users', sa.Column('relationship_status', sa.String(), nullable=True))
    op.add_column('users', sa.Column('has_kids', sa.String(), nullable=True))
    op.add_column('users', sa.Column('want_kids', sa.String(), nullable=True))
    op.add_column('users', sa.Column('height', sa.Integer(), nullable=True))
    op.add_column('users', sa.Column('education', sa.String(), nullable=True))
    op.add_column('users', sa.Column('occupation', sa.String(), nullable=True))
    op.add_column('users', sa.Column('drinking', sa.String(), nullable=True))
    op.add_column('users', sa.Column('smoking', sa.String(), nullable=True))
    op.add_column('users', sa.Column('exercise', sa.String(), nullable=True))
    op.add_column('users', sa.Column('languages', sa.String(), nullable=True))


def downgrade():
    op.drop_column('users', 'languages')
    op.drop_column('users', 'exercise')
    op.drop_column('users', 'smoking')
    op.drop_column('users', 'drinking')
    op.drop_column('users', 'occupation')
    op.drop_column('users', 'education')
    op.drop_column('users', 'height')
    op.drop_column('users', 'want_kids')
    op.drop_column('users', 'has_kids')
    op.drop_column('users', 'relationship_status')
    op.drop_column('users', 'religion')
